# 1. Register GitHub as a trusted Identity Provider in your AWS Account
resource "aws_iam_openid_connect_provider" "github" {
  url             = "https://token.actions.githubusercontent.com"
  client_id_list  = ["sts.amazonaws.com"]
  # The thumbprint is a security fingerprint for GitHub's certificates
  thumbprint_list = ["6938fd4d98bab03faadb97b34396831e3780aea1"] 
}

# 2. Create the IAM Role that GitHub will "assume"
resource "aws_iam_role" "github_oidc_role" {
  name = "github-actions-oidc-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRoleWithWebIdentity"
        Effect = "Allow"
        Principal = {
          Federated = aws_iam_openid_connect_provider.github.arn
        }
        Condition = {
          StringLike = {
            # CRITICAL: Replace 'your-username/your-repo' with your actual GitHub path
            "token.actions.githubusercontent.com:sub": "2004Asbah/aws_ansible_postgres_project/"
          },
          StringEquals = {
            "token.actions.githubusercontent.com:aud": "sts.amazonaws.com"
          }
        }
      }
    ]
  })
}

# 3. Attach Permissions to the Role
resource "aws_iam_role_policy_attachment" "oidc_admin" {
  role       = aws_iam_role.github_oidc_role.name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess" 
}