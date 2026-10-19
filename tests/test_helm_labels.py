"""Render regression tests. Requires Helm 3 and PyYAML (pip install pyyaml)."""
import json
import os
from pathlib import Path
import subprocess
import unittest

CHART = Path(__file__).resolve().parents[1] / 'k8s-cluster/ha-cluster/helm_charts'

def render(overrides=None):
    command = [os.environ.get('HELM', 'helm'), 'template', 'test', str(CHART)]
    if overrides:
        command += ['--values', '-']
    result = subprocess.run(command, input=json.dumps(overrides or {}),
                            text=True, encoding='utf-8', capture_output=True, check=True)
    import yaml
    return list(yaml.safe_load_all(result.stdout))

def statefulset(documents):
    return next(doc for doc in documents if doc and doc['kind'] == 'StatefulSet')

class LabelsTest(unittest.TestCase):
    def test_patroni_matches_pod_labels(self):
        for overrides in [{}, {'applicationName': 'custom-app', 'clusterName': 'custom-cluster'}]:
            with self.subTest(overrides=overrides):
                documents = render(overrides)
                sts = statefulset(documents)
                pod = sts['spec']['template']
                env = {e['name']: e.get('value') for e in pod['spec']['containers'][0]['env']}
                import yaml
                labels = yaml.safe_load(env['PATRONI_KUBERNETES_LABELS'])
                self.assertEqual(labels, pod['metadata']['labels'])
                self.assertEqual(labels['cluster-name'], env['PATRONI_SCOPE'])
                for service in documents:
                    if service and service['kind'] == 'Service':
                        for key, value in service['spec'].get('selector', {}).items():
                            if key != 'role':
                                self.assertEqual(labels[key], value)

if __name__ == '__main__':
    unittest.main()
