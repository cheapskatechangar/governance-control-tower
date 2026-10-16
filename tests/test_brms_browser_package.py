"""Offline structural gates for the browser-import package, not live acceptance."""
import importlib.util
from pathlib import Path
import re
import unittest
import xml.etree.ElementTree as ET

ROOT = Path(__file__).resolve().parents[1]
spec = importlib.util.spec_from_file_location('brms', ROOT / 'scripts/build_brms_browser_package.py')
brms = importlib.util.module_from_spec(spec)
spec.loader.exec_module(brms)


def walk(actions):
    for name, action in actions.items():
        yield name, action
        yield from walk(action.get('actions', {}))
        yield from walk(action.get('else', {}).get('actions', {}))


def strings(value):
    if isinstance(value, str):
        yield value
    elif isinstance(value, dict):
        for child in value.values():
            yield from strings(child)
    elif isinstance(value, list):
        for child in value:
            yield from strings(child)


class BrowserPackageTests(unittest.TestCase):
    def setUp(self):
        self.flows = {
            name: brms.workflow(name, hour, builder())
            for name, hour, builder in [
                ('Review Schedule Refresh', 6, brms.refresh_item),
                ('Review Reminders', 8, brms.reminder_item),
                ('Source Document Monitor', 7, brms.source_item),
            ]
        }

    def test_solution_declares_three_disabled_unsuffixed_flows(self):
        root = ET.parse(ROOT / 'scripts/native-brms/customizations.xml').getroot()
        flows = root.findall('./Workflows/Workflow')
        self.assertEqual(len(flows), 3)
        self.assertEqual({f.attrib['Name'] for f in flows}, {'BRMS - GCT - ' + n for n in self.flows})
        for flow in flows:
            self.assertEqual(flow.findtext('StateCode'), '0')
            self.assertEqual(flow.findtext('StatusCode'), '1')
            self.assertEqual(flow.findtext('ModernFlowType'), '0')
        manifest = ET.parse(ROOT / 'scripts/native-brms/solution.xml').getroot()
        self.assertEqual(manifest.findtext('./SolutionManifest/Version'), brms.VERSION)

    def test_dependencies_and_expression_references_resolve(self):
        def verify_level(actions):
            for action in actions.values():
                self.assertTrue(set(action.get('runAfter', {})).issubset(actions))
                verify_level(action.get('actions', {}))
                verify_level(action.get('else', {}).get('actions', {}))
        for flow in self.flows.values():
            self.assertEqual(flow['schemaVersion'], '1.0.0.0')
            actions = flow['properties']['definition']['actions']
            pairs = list(walk(actions))
            names = {name for name, _ in pairs}
            self.assertEqual(len(names), len(pairs))
            verify_level(actions)
            for text in strings(actions):
                for reference in re.findall(r"(?:body|outputs|actions|items)\('([^']+)'\)", text):
                    self.assertIn(reference, names)
                self.assertNotRegex(text, r'(?<![A-Za-z_])filter\(')

    def test_preview_gate_no_outbound_actions_and_conditional_writes(self):
        for flow in self.flows.values():
            actions = dict(walk(flow['properties']['definition']['actions']))
            gate = actions['Require_test_scope']['inputs']['content']
            for expected in [brms.ENV, 'synthetic-records-only', 'outboundRemindersEnabled', 'preview']:
                self.assertIn(expected, gate)
            self.assertIn("Department eq 'BRMS Test'", actions['Get_documents']['inputs']['parameters']['$filter'])
            for name, action in actions.items():
                if action['type'] != 'OpenApiConnection':
                    continue
                inputs = action['inputs']
                self.assertEqual(inputs['host']['apiId'], '/providers/Microsoft.PowerApps/apis/shared_sharepointonline')
                self.assertNotIn('retryPolicy', action.get('runtimeConfiguration', {}))
                self.assertIn('retryPolicy', inputs)
                self.assertEqual(inputs['authentication'], "@parameters('$authentication')")
                if inputs['host']['operationId'] == 'PostItem':
                    self.assertIn('item', inputs['parameters'])
                    self.assertIsInstance(inputs['parameters']['item'], dict)
                    self.assertFalse(any(k.startswith('item/') for k in inputs['parameters']))
                if inputs['parameters'].get('parameters/method') == 'POST':
                    self.assertIn('IF-MATCH', inputs['parameters']['parameters/headers'])
                    self.assertEqual(inputs['retryPolicy']['type'], 'none')
            self.assertEqual(actions['Get_documents']['runtimeConfiguration']['paginationPolicy']['minimumItemCount'], 100000)
            self.assertEqual(actions['For_each_document']['runtimeConfiguration']['concurrency']['repetitions'], 1)

    def test_business_dates_are_normalized_before_month_arithmetic_and_writes(self):
        for name in ['Review Schedule Refresh', 'Review Reminders']:
            actions = dict(walk(self.flows[name]['properties']['definition']['actions']))
            self.assertIn("'UTC','Eastern Standard Time','yyyy-MM-dd'", actions['Compose_reviewed_day']['inputs'])
            self.assertIn("outputs('Compose_reviewed_day')", actions['Compose_due']['inputs'])
            self.assertNotIn('LastReviewedDate', actions['Compose_due']['inputs'])
            self.assertIn('v8|', actions['Set_context']['inputs']['value'])
        refresh = dict(walk(self.flows['Review Schedule Refresh']['properties']['definition']['actions']))
        self.assertIn('convertToUtc', refresh['Compose_patch']['inputs']['NextReviewDue'])
        reminder = dict(walk(self.flows['Review Reminders']['properties']['definition']['actions']))
        self.assertIn("'UTC','Eastern Standard Time','yyyy-MM-dd'", reminder['Require_current_schedule']['inputs']['content'])
        self.assertIn('preview-v8', reminder['Compose_key']['inputs'])

    def test_owned_fields_and_actual_run_accounting(self):
        expected = {'Review Schedule Refresh': {'NextReviewDue','DaysToReview','Status'}, 'Source Document Monitor': {'SourceModifiedDate'}}
        for name, fields in expected.items():
            actions = dict(walk(self.flows[name]['properties']['definition']['actions']))
            self.assertEqual(set(actions['Compose_patch']['inputs']), fields)
        for flow in self.flows.values():
            actions = dict(walk(flow['properties']['definition']['actions']))
            record = actions['Record_run']['inputs']['parameters']['item']
            self.assertEqual(record['RunKey'], "@workflow()?['run']?['name']")
            self.assertEqual(record['ProcessedCount'], "@length(variables('Outcomes'))")
            self.assertEqual(record['SuccessCount'], "@length(body('Successful_items'))")
            self.assertEqual(record['FailureCount'], "@length(body('Failed_items'))")
            self.assertEqual(actions['Finalize']['runAfter']['Work'], brms.ALL)


if __name__ == '__main__':
    unittest.main()
