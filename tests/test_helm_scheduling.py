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

class SchedulingTest(unittest.TestCase):
    def test_defaults_omit_constraints(self):
        pod = statefulset(render())['spec']['template']['spec']
        for key in ('nodeSelector', 'affinity', 'tolerations'):
            self.assertNotIn(key, pod)

    def test_scheduling_constraints(self):
        settings = {
            'nodeSelector': {'disktype': 'ssd'},
            'tolerations': [{'key': 'database', 'operator': 'Equal', 'value': 'ivorysql', 'effect': 'NoSchedule'}],
            'affinity': {'podAntiAffinity': {'requiredDuringSchedulingIgnoredDuringExecution': [
                {'labelSelector': {'matchLabels': {'application': 'ivyhac'}},
                 'topologyKey': 'kubernetes.io/hostname'}]}},
        }
        pod = statefulset(render(settings))['spec']['template']['spec']
        for key, value in settings.items():
            self.assertEqual(pod.get(key), value, key)

if __name__ == '__main__':
    unittest.main()
