package test

import (
	"fmt"
	"testing"

	"github.com/gruntwork-io/terratest/modules/aws"
	"github.com/gruntwork-io/terratest/modules/random"
	"github.com/gruntwork-io/terratest/modules/terraform"
	"github.com/stretchr/testify/assert"
)

// An example of how to test the Terraform module in examples/terraform-aws-example using Terratest.
func TestTerraformTagsValidation(t *testing.T) {
	t.Parallel()

	expectedName := fmt.Sprintf("flugel_server_%s", random.UniqueId())

	instanceType := aws.GetRecommendedInstanceType(t, "us-east-1", []string{"t2.micro"})

	terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		TerraformDir: "../",

		// Variables to pass to our Terraform code using -var options
		Vars: map[string]interface{}{
			"instance_name": expectedName,
			"instance_type": instanceType,
		},

		EnvVars: map[string]string{
			"AWS_DEFAULT_REGION": "us-east-1",
		},
	})

	defer terraform.Destroy(t, terraformOptions)

	terraform.InitAndApply(t, terraformOptions)

	instanceID := terraform.Output(t, terraformOptions, "instance_id")
	bucketID := terraform.Output(t, terraformOptions, "bucket_id")

	instanceTags := aws.GetTagsForEc2Instance(t, "us-east-1", instanceID)
	bucketTags := aws.GetS3BucketTags(t, "us-east-1", bucketID)

	testingTag, containsTestingTag := instanceTags["Name"]
	assert.True(t, containsTestingTag)
	assert.Equal(t, "Flugel", testingTag)

	// Verify that our expected name tag is one of the tags
	instanceNameTag, containsNameTag := instanceTags["Name"]
	assert.True(t, containsNameTag)
	assert.Equal(t, "Flugel", instanceNameTag)

	instanceNameTag1, containsNameTag1 := instanceTags["Owner"]
	assert.True(t, containsNameTag1)
	assert.Equal(t, "InfraTeam", instanceNameTag1)

	bucketNameTag1, containsNameTag2 := bucketTags["Name"]
	assert.True(t, containsNameTag2)
	assert.Equal(t, "Flugel", bucketNameTag1)

	bucketNameTag2, containsNameTag3 := bucketTags["Owner"]
	assert.True(t, containsNameTag3)
	assert.Equal(t, "InfraTeam", bucketNameTag2)
}
