# Deploy an AI model on GKE with NVIDIA NIM

NIM = NVIDIA Inference Microservice

What I have here is a modified version of this [tutorial](https://docs.nvidia.com/nim/large-language-models/latest/deploy-helm.html)


## Prerequisites (GKE)
### Find out which region supports your GPU
If you have a particular GPU (or TPU) that you want to use, you will have to first check if the region you plan to deploy in supports it. Leverage `--filter` to search.

- by zone (`:` means "contains")
```sh
gcloud beta compute accelerator-types list \
    --filter="zone:( northamerica-northeast2 )"
```
- sample output:
```console
NAME                   ZONE                       DESCRIPTION
nvidia-l4              northamerica-northeast2-b  NVIDIA L4
nvidia-l4-vws          northamerica-northeast2-b  NVIDIA L4 Virtual Workstation
nvidia-l4              northamerica-northeast2-a  NVIDIA L4
nvidia-l4-vws          northamerica-northeast2-a  NVIDIA L4 Virtual Workstation
nvidia-h100-80gb       northamerica-northeast2-c  NVIDIA H100 80GB
nvidia-h100-mega-80gb  northamerica-northeast2-c  NVIDIA H100 80GB MEGA
```

- by GPU name (`=` means "exact match")
```sh
gcloud beta compute accelerator-types list \
    --filter="name=( nvidia-l4 )"
```
- sample output:
```console
NAME       ZONE                       DESCRIPTION
nvidia-l4  us-central1-a              NVIDIA L4
nvidia-l4  us-central1-b              NVIDIA L4
nvidia-l4  us-central1-c              NVIDIA L4
nvidia-l4  europe-west1-b             NVIDIA L4
nvidia-l4  europe-west1-c             NVIDIA L4
...
...
nvidia-l4  me-central2-c              NVIDIA L4
nvidia-l4  me-central2-a              NVIDIA L4
```

> [!TIP]
> You can use `AND` to combine multiple filter criteria


### Find out your machine type
GKE supports a wide range of machine types which support different NVIDIA GPUs.  You can read the documentation [here](https://cloud.google.com/compute/docs/accelerator-optimized-machines)

You'll want to use *g2-standard-4* as it is the cheapest and the GPU it supports are the [NVIDIA L4's](https://cloud.google.com/compute/docs/gpus#l4-gpus).

> [!NOTE]
> You will have to take your machine type's memory into consideration when deciding on the type of model to use.  The *g2-standard-4* has 16GB of memory so I opted to run the Gemma 3 1B Instruct model. If you wanted to run the Meta Llama 3 8B Instruct, then you'd want the *g2-standard-12* machine type or better.


### Installing the NVIDIA GPU Operator (optional)
This part is managed for you as long as you left the `gpu_driver_version` as `LATEST` (default).  If you wish to install your own, you would set it to `INSTALLATION_DISABLED` instead and install it via the helm chart below (I haven't tried the manual install yet):
```sh
helm repo add nvidia https://helm.ngc.nvidia.com/nvidia

helm repo update
```

- [common deployment scenarios](https://docs.nvidia.com/datacenter/cloud-native/gpu-operator/latest/getting-started.html#common-deployment-scenarios)
- [common helm chart customization options](https://docs.nvidia.com/datacenter/cloud-native/gpu-operator/latest/getting-started.html#common-chart-customization-options)

```sh
helm install --wait --generate-name \
    -n gpu-operator --create-namespace \
    nvidia/gpu-operator \
    --version=v25.3.0 \
    --set [OPTION_NAME]=[OPTION_VALUE]
```


## Prerequisites (NIM demo)
You'll need to [make an NVIDIA account](https://build.nvidia.com/) in order to get an API key so you are able to download a NIM container. 

- export the key to env var, `NGC_API_KEY` and create two secrets 
```sh
export NGC_API_KEY='nvapi-1234567890qwertyuiopasdfghjklzxcvbnm'

kubectl create secret docker-registry ngc-secret --docker-server=nvcr.io --docker-username='$oauthtoken' --docker-password=$NGC_API_KEY

kubectl create secret generic ngc-api --from-literal=NGC_API_KEY=$NGC_API_KEY
```

### Deploying Model via Helm Chart
- fetch the [helm chart](https://catalog.ngc.nvidia.com/orgs/nim/helm-charts/nim-llm):
```sh
helm fetch https://helm.ngc.nvidia.com/nim/charts/nim-llm-1.13.1.tgz \
    --username='$oauthtoken' \
    --password=$NGC_API_KEY
```

- you'll want a custom values file that defines and LLM mode and the corresponding image tag:
```yaml
image:
  repository: "nvcr.io/nim/google/gemma-3-1b-it" # container location
  tag: 1.12.0 # NIM version you want to deploy
model:
  ngcAPISecret: ngc-api # k8s secret containing your NGC_API_KEY
  resources:
    limits:
      nvidia.com/gpu: 1
    requests:
      nvidia.com/gpu: 1
  persistence:
    enabled: true
  imagePullSecrets:
    - name: ngc-secret
```

> [!TIP]
> You can find the various models and versions (image tag) [here](https://docs.nvidia.com/nim/large-language-models/latest/supported-models.html#optimized-models)


### Deploying the Model
```sh
helm install my-nim nim-llm-1.13.1.tgz -f nim_custom_value.yaml
```

- sample output
```console
NAME: my-nim
LAST DEPLOYED: Fri Sep  5 18:30:19 2025
NAMESPACE: default
STATUS: deployed
REVISION: 1
NOTES:
Thank you for installing nim-llm.

**************************************************
| It may take some time for pods to become ready |
| while model files download                     |
**************************************************

Your NIM version is: 1.12.0
```

It took ~10 min before it was ready to serve traffic, so be patient.  Here's a snippet of what the container log looks like:
```console
===========================================
== NVIDIA Inference Microservice LLM NIM ==
===========================================

NVIDIA Inference Microservice LLM NIM Version 1.12.0
Model: google/gemma-3-1b-it

Container image Copyright (c) 2016-2025, NVIDIA CORPORATION & AFFILIATES. All rights reserved.

The NIM container is governed by the NVIDIA Software License Agreement (found at https://www.nvidia.com/en-us/agreements/enterprise-software/nvidia-software-license-agreement/) and the Product-Specific Terms for NVIDIA AI Products (found at https://www.nvidia.com/en-us/agreements/enterprise-software/product-specific-terms-for-ai-products/).

A copy of this license can be found under /opt/nim/LICENSE.

The model is governed by NVIDIA Community Model License (https://www.nvidia.com/en-us/agreements/enterprise-software/nvidia-community-models-license/).

ADDITIONAL INFORMATION: Gemma Terms of Use (found at https://ai.google.dev/gemma/terms).
INFO 09-05 22:37:02 [__init__.py:239] Automatically detected platform cuda.

INFO: No proxy configuration detected. Models will be downloaded directly from the internet.
INFO 09-05 22:37:22 [__init__.py:239] Automatically detected platform cuda.
{"level": "None", "time": "None", "file_name": "None", "file_path": "None", "line_number": "-1", "message": "INFO 09-05 22:37:22 [__init__.py:239] Automatically detected platform cuda.", "exc_info": "None", "stack_info": "None"}
...
...
...
```

### Testing
- port forward for testing:
```sh
kubectl port-forward service/my-nim-nim-llm 8000:8000
```

- `bash ./curl_request.sh | jq .`:
```json
{
  "id": "chatcmpl-7556d15f6692494d9e8bb338d697be39",
  "object": "chat.completion",
  "created": 1757112379,
  "model": "google/gemma-3-1b-it",
  "choices": [
    {
      "index": 0,
      "message": {
        "role": "assistant",
        "reasoning_content": null,
        "content": "Okay, fantastic! A 4-day trip to Spain sounds wonderful – it’s a really diverse country with so much to offer. To help me create the *perfect* itinerary for you, let’s narrow things down a bit. But first, let’s start with some general ideas and then we can delve deeper based on your interests!",
        "tool_calls": []
      },
      "logprobs": null,
      "finish_reason": "stop",
      "stop_reason": "\n"
    }
  ],
  "usage": {
    "prompt_tokens": 36,
    "total_tokens": 108,
    "completion_tokens": 72,
    "prompt_tokens_details": null
  },
  "prompt_logprobs": null
}
```
