package test

import (
	"fmt"
	"testing"
	"strings"

	"github.com/aws/aws-sdk-go/aws"
	"github.com/aws/aws-sdk-go/aws/session"
	"github.com/aws/aws-sdk-go/service/s3"
	"github.com/gruntwork-io/terratest/modules/random"
	"github.com/gruntwork-io/terratest/modules/terraform"
	"github.com/stretchr/testify/assert"
)

func TestTerragruntS3Bucket(t *testing.T) {
	t.Parallel()

	// Create a valid S3 bucket name: lowercase, no underscores, between 3-63 chars
	bucketName := fmt.Sprintf("terratest-s3-%s", strings.ToLower(random.UniqueId()))

	// Set the working directory to the terragrunt S3 module
	// Adjust this path to match your actual project structure
	terragruntDir := "../terragrunt/environments/dev/s3-bucket"
    
	// Set up Terraform options but use terragrunt as the binary
	terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		TerraformDir: terragruntDir,
		TerraformBinary: "terragrunt",
		EnvVars: map[string]string{
			"AWS_REGION": "us-east-1",
			"TG_VAR_environment": "test",
		},
		// Just set the critical variables, use existing tfvars for the rest
		Vars: map[string]interface{}{
			"bucket_name": bucketName,
			"owner": "terratest",
			"enable_logging": false,  // Disable logging for tests
		},
	})

	// At the end of the test, run `terragrunt destroy`
	defer terraform.Destroy(t, terraformOptions)

	// Run `terragrunt init` and `terragrunt apply`
	terraform.InitAndApply(t, terraformOptions)
	
	// Get the bucket name from the outputs
	bucketID := terraform.Output(t, terraformOptions, "bucket_id")
	
	// Get the AWS region
	awsRegion := "us-east-1" // Using hardcoded region instead of aws.GetRegion()

	// Create an AWS session
	awsSession, err := session.NewSession(&aws.Config{
		Region: aws.String(awsRegion),
	})
	if err != nil {
		t.Fatal(err)
	}

	s3Client := s3.New(awsSession)

	// Test 1: Verify that the S3 bucket exists
	t.Run("BucketExists", func(t *testing.T) {
		// Using a direct check instead of aws.AssertS3BucketExists
		_, err := s3Client.HeadBucket(&s3.HeadBucketInput{
			Bucket: aws.String(bucketID),
		})
		assert.NoError(t, err, "S3 bucket should exist: %s", bucketID)
	})

	// Test 2: Verify that the S3 bucket has encryption enabled
	t.Run("BucketIsEncrypted", func(t *testing.T) {
		encryptionConfig, err := s3Client.GetBucketEncryption(&s3.GetBucketEncryptionInput{
			Bucket: aws.String(bucketID),
		})
		if err != nil {
			t.Fatal(err)
		}

		// Check if there's at least one encryption rule
		assert.True(t, len(encryptionConfig.ServerSideEncryptionConfiguration.Rules) > 0, "Bucket should have encryption rules")
		
		// Check if SSE is enabled with AES256
		rule := encryptionConfig.ServerSideEncryptionConfiguration.Rules[0]
		assert.Equal(t, "AES256", *rule.ApplyServerSideEncryptionByDefault.SSEAlgorithm, "Bucket should use AES256 encryption")
	})

	// Test 3: Verify that the tags are applied correctly
	t.Run("BucketHasCorrectTags", func(t *testing.T) {
		tagsOutput, err := s3Client.GetBucketTagging(&s3.GetBucketTaggingInput{
			Bucket: aws.String(bucketID),
		})
		if err != nil {
			t.Fatal(err)
		}

		tags := make(map[string]string)
		for _, tag := range tagsOutput.TagSet {
			tags[*tag.Key] = *tag.Value
		}

		// Check the environment tag (should be "test" from our environment variable)
		assert.Equal(t, "test", tags["environment"], "Bucket should have environment tag set to 'test'")
		
		// Check the owner tag
		assert.Equal(t, "terratest", tags["owner"], "Bucket should have owner tag set to 'terratest'")
		
		// Check that we have other required tags (from existing tfvars file)
		assert.Contains(t, tags, "Project", "Bucket should have Project tag")
		assert.Contains(t, tags, "CostCenter", "Bucket should have CostCenter tag")
	})

	// Test 4: Verify that public access is blocked (AWS S3 security best practice)
	t.Run("BucketBlocksPublicAccess", func(t *testing.T) {
		publicAccessBlock, err := s3Client.GetPublicAccessBlock(&s3.GetPublicAccessBlockInput{
			Bucket: aws.String(bucketID),
		})
		if err != nil {
			t.Fatal(err)
		}

		assert.True(t, *publicAccessBlock.PublicAccessBlockConfiguration.BlockPublicAcls, "BlockPublicAcls should be enabled")
		assert.True(t, *publicAccessBlock.PublicAccessBlockConfiguration.BlockPublicPolicy, "BlockPublicPolicy should be enabled")
		assert.True(t, *publicAccessBlock.PublicAccessBlockConfiguration.IgnorePublicAcls, "IgnorePublicAcls should be enabled")
		assert.True(t, *publicAccessBlock.PublicAccessBlockConfiguration.RestrictPublicBuckets, "RestrictPublicBuckets should be enabled")
	})

	// Test 5: Verify that versioning is enabled (AWS S3 security best practice)
	t.Run("BucketHasVersioningEnabled", func(t *testing.T) {
		versioningOutput, err := s3Client.GetBucketVersioning(&s3.GetBucketVersioningInput{
			Bucket: aws.String(bucketID),
		})
		if err != nil {
			t.Fatal(err)
		}

		assert.Equal(t, "Enabled", *versioningOutput.Status, "Bucket versioning should be enabled")
	})
	
	// Test 6: Verify that secure transport policy is enforced (AWS S3 security best practice)
	t.Run("BucketEnforcesSecureTransport", func(t *testing.T) {
		policyOutput, err := s3Client.GetBucketPolicy(&s3.GetBucketPolicyInput{
			Bucket: aws.String(bucketID),
		})
		if err != nil {
			t.Fatal(err)
		}
		
		// Verify policy contains secure transport requirement
		policyStr := *policyOutput.Policy
		assert.Contains(t, policyStr, "aws:SecureTransport", "Bucket policy should enforce HTTPS")
		assert.Contains(t, policyStr, "false", "Bucket policy should deny non-HTTPS access")
	})
}