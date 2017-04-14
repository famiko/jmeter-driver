# jmeter-driver

Driver script for distributed JMeter testing.

## Depends on
docker
```
curl -sSL https://get.docker.com/ | sh
```

## How to use
```
./driver.sh -h
Usage: ./driver.sh [-n num-jmeter-servers] [-s jmx] [-w work-dir]
-h      This help message
-n      The required number of servers
-s      The JMX script file
-w      The working directory. Logs are relative to it.
```
Containers will stop and be removed when test finish.
Result will be in the folder `<work-dir>/<process-id>/client`.
Result contains log,jtl and output html dashboard.

You can use jmeter to generate custom result from the jtl file.
## Example
```
mkdir workdir
./driver.sh -n 2 -s jmxs/test.jmx -w workdir
```
In this example,The jmx file will start a forever test.
You need to enter the client container to stop test.
```
docker exec -i -t <client-container-id>(tag:jmeter-client) sh
shutdown.sh
```
Wait the script clean containers.
