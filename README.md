# azure-faceapi-largepersongrouputils
Simple set of shell scripts to create, populate and train a LargePersonGroup
Works on the basis that you have a directory called 'files', and in that directory, there are a number of files whose names correspond to an identifier used to identify individuals
In our example, we have files/AlexSmith.jpg, and subsequently after the execution of this script, a person with name "AlexSmith" will be created, and the image associated with that person.

Instructions:

* Edit the scripts to include your API key, change the region if needed, and configure a custom LargePersonGroup name if needed
* Run lpg-create.sh
 * This will create a LargePersonGroup with the name 'employees'
* Ensure that all files are in files/
* Run lpg-populate.sh