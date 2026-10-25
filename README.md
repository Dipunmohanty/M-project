# M-Project

A lightweight static website served by Nginx and deployed to Google Kubernetes Engine (GKE). GitHub Actions builds and smoke-tests the Docker image, scans the source and image for security issues, publishes the image to Docker Hub, and deploys the Kubernetes resources.

## Contents

- `html/` — website homepage and custom error pages.
- `default.conf` — Nginx site configuration.
- `Dockerfile` — container image definition.
- `k8s-service.tmpl.yml` and `k8s-ingress.tmpl.yml` — Kubernetes resource templates.
- `k8s-service.yml` and `k8s-ingress.yml` — checked-in Kubernetes manifests.
- `.github/workflows/ai-review.yml` — pull-request checks and optional AI review.
- `.github/workflows/deploy.yml` — production build, publish, and deployment pipeline.

## Run locally

### Build and run the website

Install Docker, then run:

```sh
docker build -t m-project:local .
docker run --rm -p 8080:80 m-project:local
```

Open <http://localhost:8080>. To check the custom not-found page:

```sh
curl -i http://localhost:8080/this-page-does-not-exist
```

### Run the CI smoke test

On Linux, macOS, or Windows with Git Bash and Docker available:

```sh
bash .github/scripts/verify-image.sh m-project:ci
```

The script builds the image, checks that the homepage responds, and confirms that a missing page returns the custom `404` page.

## AI review configuration

The optional local environment file is for local tooling. Copy `.env.example` to `.env`, replace the placeholder with your own API key, and optionally set a model:

```sh
cp .env.example .env
```

Review `.env` before loading it, then source it in a Bash shell:

```sh
source .env
```

The root `.gitignore` excludes `.env` and other `.env.*` files while allowing the safe `.env.example` template. Never commit an API key. If a key is exposed, revoke it and create a replacement.

**GitHub Actions does not read your local `.env` file.** Configure these repository settings for the pull-request workflow:

1. Add an Actions secret named `OPENAI_API_KEY` containing the OpenAI API key.
2. Optionally add an Actions variable named `CODEX_MODEL` with a model supported by your account. If it is unset or blank, the Codex action chooses its default model.
3. Allow GitHub Actions to write to pull-request branches if automatic HTML fixes are desired. Branch protections can still prevent the bot from pushing.

The AI review only attempts small, behavior-preserving changes to existing HTML files. Proposed changes are checked for scope, patch validity, build/smoke-test behavior, and security findings before a separate job commits them. Larger changes are reported on the pull request for maintainer review. Concrete security or availability blockers fail the review gate; other recommendations do not block on their own.

Pull requests from forks receive the deterministic build and security checks, but skip the AI job so repository secrets and write access are not exposed to untrusted code.

## CI/CD setup

The production workflow runs on pushes to `main`. It requires the following GitHub Actions configuration:

### Secrets

- `DOCKERHUB_USERNAME` — Docker Hub account used to publish the image.
- `DOCKERHUB_TOKEN` — Docker Hub access token.
- `GCP_WORKLOAD_PROVIDER` — Google Cloud Workload Identity Provider resource name.
- `GCP_SERVICE_ACCOUNT` — Google Cloud service account email used by GitHub Actions.
- `GCP_CLUSTER_NAME` — GKE cluster name.
- `GCP_REGION` — GKE region or zone.
- `GCP_PROJECT_ID` — Google Cloud project ID.

The Google Cloud service account and Workload Identity Provider must be configured to permit this repository's deployment workflow to authenticate and deploy to the cluster.

### Deployment configuration

`active-config.env` supplies the values used to compile the Kubernetes templates:

- `APP_NAME`
- `DOCKERHUB_USERNAME`
- `CONTAINER_PORT`
- `INGRESS_NAME`

Review and update the configuration and Kubernetes templates for the intended environment before enabling production deployment. Changes to infrastructure or deployment configuration are not auto-applied by the AI review.

The deployment pipeline first builds and smoke-tests the site, then runs Trivy scans for critical and high severity source/image findings. Only after these checks pass does it publish the image and deploy the service and ingress to GKE.

## Pull-request gates

The pull-request workflow runs the image smoke test and Trivy security scans. On same-repository pull requests, it also runs the OpenAI Codex review. A secret scan runs before repository context is sent to the AI service. Critical/high Trivy findings, failed smoke tests, and concrete AI-reported security or availability blockers fail the corresponding gate.

To enforce the checks before merging, configure repository branch protection to require the workflow's `quality-gates` and `validate-ai-changes` checks. Validate the exact check names shown by GitHub after the first workflow run.

## License

No license file is currently included in this repository.
