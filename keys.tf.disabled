resource "aws_key_pair" "deployer" {
  key_name   = "${var.project_name}-key"
  public_key = file(".ssh/terraform-lab.pub")
}
