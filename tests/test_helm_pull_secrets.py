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

class PullSecretsTest(unittest.TestCase):
    def test_default_omits_pull_secrets(self):
        pod = statefulset(render())['spec']['template']['spec']
        self.assertNotIn('imagePullSecrets', pod)

    def test_custom_pull_secrets(self):
        secrets = [{'name': 'registry-one'}, {'name': 'registry-two'}]
        pod = statefulset(render({'imagePullSecrets': secrets}))['spec']['template']['spec']
        self.assertEqual(pod.get('imagePullSecrets'), secrets)

if __name__ == '__main__':
    unittest.main()
