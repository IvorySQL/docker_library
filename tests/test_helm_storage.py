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

class StorageTest(unittest.TestCase):
    def test_independent_claim_sizes(self):
        for overrides, data_size, config_size in [
            ({}, '1Gi', '16Mi'),
            ({'pvc': {'storageSize': '32Gi', 'confStorageSize': '64Mi'}}, '32Gi', '64Mi'),
        ]:
            with self.subTest(overrides=overrides):
                claims = statefulset(render(overrides))['spec']['volumeClaimTemplates']
                sizes = {c['metadata']['name']: c['spec']['resources']['requests']['storage'] for c in claims}
                self.assertEqual(sizes, {'pgdata': data_size, 'ivyhac-config': config_size})

if __name__ == '__main__':
    unittest.main()
