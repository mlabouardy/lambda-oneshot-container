package main

import (
	"errors"
	"fmt"
	"io/ioutil"
	"net/http"
	"os"
	"strings"

	"github.com/aws/aws-lambda-go/lambda"
)

func getToken() ([]string, error) {
	url := fmt.Sprintf(`%s/crumbIssuer/api/xml?xpath=concat(//crumbRequestField,":",//crumb)`, os.Getenv("JENKINS_HOST"))

	client := http.Client{}
	req, err := http.NewRequest("GET", url, nil)
	if err != nil {
		return []string{}, err
	}

	req.SetBasicAuth(os.Getenv("JENKINS_USERNAME"), os.Getenv("JENKINS_PASSWORD"))

	resp, err := client.Do(req)
	if err != nil {
		return []string{}, err
	}
	defer resp.Body.Close()

	data, _ := ioutil.ReadAll(resp.Body)
	if err != nil {
		return []string{}, err
	}

	return strings.Split(string(data), ":"), nil
}

func triggerJob() error {
	url := fmt.Sprintf(`%s/job/%s/build`, os.Getenv("JENKINS_HOST"), os.Getenv("JENKINS_JOB"))

	client := http.Client{}
	req, err := http.NewRequest("POST", url, nil)
	if err != nil {
		return err
	}

	crumb, err := getToken()
	if err != nil {
		return err
	}

	req.Header.Set(crumb[0], crumb[1])
	req.SetBasicAuth(os.Getenv("JENKINS_USERNAME"), os.Getenv("JENKINS_PASSWORD"))

	resp, err := client.Do(req)
	if err != nil {
		return err
	}
	defer resp.Body.Close()

	if resp.StatusCode != 201 {
		return errors.New("Cannot trigger job")
	}

	return nil
}

func main() {
	lambda.Start(triggerJob)
}
