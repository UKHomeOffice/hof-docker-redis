# docker-redis

[![Build Status](https://travis-ci.org/UKHomeOffice/docker-redis.svg?branch=master)](https://travis-ci.org/UKHomeOffice/docker-redis)

HOF version of Docker image for redis. This image is designed to be used with kubernetes, it
may work outside kubernetes as well.

This repository is a fork of the official UK Home Office Redis Docker image, originally hosted at UKHomeOffice/docker-redis.
Please ensure this repository remains in sync with the upstream source to reflect the latest updates and improvements.

Note: Fedora is currently unsupported by Trivy for vulnerability scanning. To ensure that vulnerabilities are properly detected and addressed in our CI/CD pipeline, we have opted to use Rocky Linux as the base image.

It is highly recommended to read through [redis sentinel
documentation](http://redis.io/topics/sentinel).

## Launching it in kubernetes

## Redis persistence

This repository uses a `StatefulSet` (`kube/redis-controller.yaml`) with per-pod EBS-backed PVC.

First create the headless Redis service, then the Redis workload. Both
containers will notice that `${REDIS_SENTINEL_SERVICE_HOST}` and
`${REDIS_SENTINEL_SERVICE_PORT}` are empty and assume that this is an initial
bootstrap of redis. Redis sentinel will connect to the master at `$(hostname
-i)` and start monitoring it.

```
kubectl apply -f kube/redis-headless-service.yaml
kubectl apply -f kube/redis-controller.yaml
```

Then you need to create redis sentinel service, which will become your redis
sentinel endpoint for the following redis pods.

```
kubectl apply -f kube/redis-sentinel-service.yaml
```

Once the service is up and running, you can check whether it is working
properly. Run the following command in some temporary container.

```
redis-cli -h ${REDIS_SENTINEL_SERVICE_HOST} -p 26379 INFO
```

Next, we can start scaling our redis out. It is recommended to add redis and
redis-sentinel replicas one by one.

```
kubectl scale statefulset redis --replicas=2
```

Wait a minute and check on the sentinel service `redis-cli -h
${REDIS_SENTINEL_SERVICE_HOST} -p 26379 INFO`, then scale to `--replicas=3`.

## EBS PVC configuration

The StatefulSet in `kube/redis-controller.yaml` uses:

- `volumeClaimTemplates`
- `storageClassName: gp3`
- `accessModes: ReadWriteOnce`
- `storage: 5Gi`

Update `storageClassName` and size to match your cluster policy if needed.

## Backup and snapshot options

Two practical options for EBS-backed Redis data:

1. EBS CSI VolumeSnapshots:
	- Create `VolumeSnapshotClass` and scheduled `VolumeSnapshot` resources.
	- Restore by creating a new PVC from a snapshot.
2. AWS Backup for EBS:
	- Tag and include PVC-backed EBS volumes in a backup plan.
	- Manage retention and cross-region copy in AWS Backup policies.

Suggested baseline:

- Hourly snapshot retention for 24 hours.
- Daily snapshot retention for 14 to 30 days.
- Restore test at least once per quarter.

## Git Tags and Release Workflow

This repository uses Git tags to trigger the release pipeline, build container images, and push them to the Quay.io container registry.

#### Workflow Overview

Developers push a Git tag following Semantic Versioning (e.g., 1.0.0).

The Drone CI pipeline is automatically triggered only when the tag is pushed from the master branch.

A Docker image is built and pushed to Quay.io.

The image is tagged with:

the semantic version (e.g., 1.0.0)

a content-addressable digest (@sha256:...)

The complete image reference can be used in the format:
**quay.io/yourorg/your-image:1.0.0@sha256:<digest>**

**Tagging for Releases**

To release a new version, follow these steps on the master branch only:

**Make sure you're on the master branch**

git checkout master

**Create and push a semantic version tag**

git tag 1.2.3
git push origin 1.2.3

**Alternatively,** We can create Tags from Git Hosting UI instead of CLI commands

We can also create tags directly from Git hosting provider’s web interface e.g., GitHub

Go to the Releases or Tags section of the repository

Click "Create a new release" or "Add tag"

Use the proper version format (e.g., 1.2.3) and make sure it points to the master branch

This is a convenient way for team members to trigger a release without using the command line.


###  Release Tagging Guidelines for Contributors

When creating a new Git tag (either via CLI or Git UI), please follow these practices to ensure clear, traceable, and production-ready releases:

Attach release notes or changelogs to a tag

Link to issues, PRs, and milestones

Create pre-releases for testing before full deployment

This turns a simple tag into a full-fledged release artifact.


**Important:**

Use valid Semantic Versioning format: v<MAJOR>.<MINOR>.<PATCH> (e.g., 1.0.0, 2.3.1)

The Drone CI pipeline is configured to only trigger on tags created from the master branch.

#### Reason for Usage of image:tag@digest

The format image:tag@digest combines:

Tag (human-readable version, like 1.2.3)

Digest (immutable SHA-256 content identifier)

The digest SHA (sha256:<digest>) is a cryptographic hash that uniquely identifies the image content. You can retrieve it from Quay.io after the image is pushed:

**This guarantees:**

'Consistency' – The image always resolves to the same content.

'Traceability' – You can trace exactly which build and source it came from.

'Security' – Prevents tampering or tag overwriting in registries.