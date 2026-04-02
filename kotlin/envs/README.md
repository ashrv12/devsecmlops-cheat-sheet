# How to add environment variables to kotlin quarkus?

Quarkus converts a GREETING_NAME=john environment variable into a greeting.name property.

```kotlin
@ConfigProperty(name = "greeting.name", defaultValue = "default")
```

```kotlin
package com.example

import jakarta.ws.rs.GET
import jakarta.ws.rs.Path
import jakarta.ws.rs.Produces
import jakarta.ws.rs.core.MediaType
import org.eclipse.microprofile.config.inject.ConfigProperty

@Path("/hello")
class GreetingResource {

    @ConfigProperty(name = "greeting.name", defaultValue = "default")
    lateinit var name: String

    @GET
    @Produces(MediaType.TEXT_PLAIN)
    fun hello(): String {
        return "Hello from the big big $name"
    }
}
```

## When doing local development

It's important to note that quarkus does support .env files locally so we can use the .env file as variables for our environment locally.

```txt
DB_HOST=localhost
DB_PORT=5432
```

So just use the file in the root of your project.

## When deploying

When deploying the project to your DEV/PRE/PROD servers it is very important to note that you should always add default values to the code and add double checks, but quarkus allows you to build the image with no environment variables set so when you deploy you can pass the env variable to the run command or deployment manifest or docker env configuration. Or we could just add the environment variables as a file and mount a .env next to the native executable binary.

```bash
docker run -e GREETING_NAME=sersan -p 8080:8080 ubi
```
