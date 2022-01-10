# UBI8-postgres-src

Postgres docker image based on UBI 8, build from Postgres source code, compatible with openshift

You like it ? Click there => [!["You like it ?"](https://www.buymeacoffee.com/assets/img/custom_images/orange_img.png)](https://www.buymeacoffee.com/sorriso)

## prerequisite:

- docker desktop is installed & running

- UBI8 image imported in docker repository (see command to run in "DokerFile"), update the image version if needed

- optional : python installed (for testing)

## How to make it working :

- rename (in /test folder) "env.template" to ".env" and set "ROOT_PATH" variable in it

- create server.key, server.pem & rootCA.pem files and store them in "/cert" folder

- optional : create client.key, client.pem ( with the same rootCA.pem) files and store them in "/test/ssl/" folder

- run "./1-build.sh" to compile docker image

- once the docker image compiled, go to "/test" folder and use "./1-start" & "3-stop.sh"

- optional : run "2-runPython.sh" (some library need to be installed, see in "test.py" file)
