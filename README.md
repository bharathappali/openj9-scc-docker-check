# SCC check for OpenJ9

This repo holds the script to run an experiment which uses petclinic application to describe the advantage of using shared class cache (SCC in short) which comes packaged along with openj9 official docker images, This experiment uses `adoptopenjdk:15-openj9` docker image (based on ubuntu).

### Quick Start

[To proceed you need a working docker setup & ports `10080` and `10081` free]

```
git clone https://github.com/bharathappali/openj9-scc-docker-check.git
cd openj9-scc-docker-check
./scc_check.sh
```

### Experiment flow

If we take a look at the dockerfile `Dockerfile_petclinic_openj9_scc`

```
FROM adoptopenjdk:15-openj9

RUN apt update \
    && apt install -y git \
    && mkdir -p app \
    && cd app \
    && git clone https://github.com/spring-projects/spring-petclinic.git \
    && cd spring-petclinic \
    && ./mvnw package

CMD java -jar /app/spring-petclinic/target/*.jar
```

We install git and clone `spring-petclinic` into `/app` directory and run a `mvn package` to build the application

In the `scc_check.sh` script we 

- We check for SCC size in `/opt/java/.scc/` (15MB in adoptopenjdk:15-openj9 image as of Oct 29, 2020)   
- Start two application instances one which uses SCC and the other doesn't
- We control the SCC usage via OpenJ9's env var `OPENJ9_JAVA_OPTIONS` and we set JVM option `-Xshareclasses` to `none` (which makes java (OpenJ9 VM) not to use shared class cache)
- Once both the applications are up and running, we parse the logs to get the startup time of application


In a test run we have seen a 6 seconds improvement in startup time, Well this actually varies depending on the system usage in which its running. Would suggest to run this on an ideal box to get the exact improvement. (This script uses cpus set to 1 and memory to 256MB to make a nearly similar conditions for both the instances)

```
Petclinic Startup with SCC : 22.072 seconds.
Petclinic Startup without SCC : 28.407 seconds.
```




