- Resource: CPU
  "Request (Minimum)": "16000m (16 Cores)"
  "Limit (Maximum)": "20000m (20 Cores)"
  Why?: "Gradle and Mandrel are highly parallel. Native image generation will consume all available cores if not capped."
- Resource: Memory
  "Request (Minimum)": 8Gi
  "Limit (Maximum)": 24Gi
  Why?: "Critical: Native image builds often fail with less than 8GB. 16GB provides a safe buffer for large classpath/complex apps."
- Resource: "Ephemeral Storage"
  "Request (Minimum)": 10Gi
  "Limit (Maximum)": 20Gi
  Why?: "Mandrel and Gradle caches can grow quickly."

## Optimizing Mandrel for Kubernetes

When running inside a container, Mandrel might not correctly "see" the cgroup limits and might try to claim the full 512GB of your host. To prevent this, pass these flags in your Quarkus build command

```bash
./gradlew build -Dquarkus.native.enabled=true \
    -Dquarkus.native.native-image-xmx=12g \
    -Dquarkus.native.container-build=false
```

-Dquarkus.native.native-image-xmx=12g: Tells Mandrel exactly how much heap it can use. Set this slightly lower than your Pod's memory limit.

Poly Tool & Gradle: Since you are adding these manually to the runner image, ensure they are in the PATH and that the GRADLE_USER_HOME is pointed to your persistent mount.

### Option A: Persistent Volume Claims (PVC)

Using a specific PVC for build folders (like .gradle and build/) is the most straightforward local method.

How: Mount a ReadWriteOnce (RWO) PVC to **/home/runner/.gradle** and the project workspace.

Pros: Very low latency; simple to set up.

Cons: Since your nodes are separate, an RWO volume will "lock" a runner to a specific node unless you use a distributed filesystem like Longhorn or Ceph.

### Option B: Dedicated Gradle Build Cache (Recommended)

Instead of fighting with PVCS and "node affinity," use a Remote Build Cache. This allows your runners to share build outputs across nodes and even between different runner pods.

Tool: Use the Gradle Remote Build Cache Docker image.

How: Deploy the cache as a separate service in your cluster. Configure your settings.gradle.kts:

Kotlin

```settings.gradle.kts
buildCache {
  remote<HttpBuildCache> {
    url = uri("http://gradle-cache-service:8080/cache/")
    isPush = true
  }
}
```

| Runner Type         | CPU Request/Limit | RAM Request/Limit | Strategy                                                                         |
| ------------------- | ----------------- | ----------------- | -------------------------------------------------------------------------------- |
| Production (Native) | 4000m / 12000m    | 12Gi / 24Gi       | High CPU burst for static analysis; high RAM for native image.                   |
| Dev/Test (JAR)      | 1000m / 2000m     | 2Gi / 4Gi         | Standard Quarkus JVM build. Kotlin DSL will spike CPU during script compilation. |
