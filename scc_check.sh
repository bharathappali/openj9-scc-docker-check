#!/bin/bash

echo "Generating docker image : OpenJDK 15 - OpenJ9 - Petclinic"
docker build -t sample-scc-petclinic -f Dockerfile_petclinic_openj9_scc .
echo ""

echo -n "Shared Class Cache Size : "
SCC_SIZE=$(docker run --rm -it sample-scc-petclinic /bin/ls -lh /opt/java/.scc/ | cut -d ' ' -f 5 | tr -d '\040\011\012\015')
echo "${SCC_SIZE}"
echo ""

echo -n "Starting petclinic with scc ... "
container_one=$(docker run --rm --cpus 1 -m256m -p 10080:8080 -d sample-scc-petclinic)
echo "Done."
echo ""

echo -n "Starting petclinic without scc ... "
container_two=$(docker run --rm -e OPENJ9_JAVA_OPTIONS="-Xshareclasses:none" --cpus 1 -m256m -p 10081:8080 -d sample-scc-petclinic)
echo "Done."
echo ""
container_one_status=$(curl -o /dev/null --silent --head --write-out '%{http_code}' http://localhost:10080)
container_two_status=$(curl -o /dev/null --silent --head --write-out '%{http_code}' http://localhost:10081)

echo -n "Sleeping till applications are up ."
while [ "${container_one_status}" != "200" ] || [ "${container_two_status}" != "200" ]
do
    sleep 1
    container_one_status=$(curl -o /dev/null --silent --head --write-out '%{http_code}' http://localhost:10080)
    container_two_status=$(curl -o /dev/null --silent --head --write-out '%{http_code}' http://localhost:10081)
    echo -n "."
done

echo " Done."

echo -n "Petclinic Startup with SCC : "
STARTUP_WITH_SCC=$(docker logs "${container_one}" 2>&1 | grep "Started PetClinicApplication in" | cut -d ":" -f 4 | cut -d " " -f 5)
echo "${STARTUP_WITH_SCC} seconds."


echo -n "Petclinic Startup without SCC : "
STARTUP_WITHOUT_SCC=$(docker logs "${container_two}" 2>&1 | grep "Started PetClinicApplication in" | cut -d ":" -f 4 | cut -d " " -f 5)
echo "${STARTUP_WITHOUT_SCC} seconds."

echo -n "Cleaning Up container ... "
docker stop "${container_one}" "${container_two}" 2>&1 > /dev/null
echo "Done."

