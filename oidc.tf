# 1. Register GitHub as a trusted Identity Provider in AWS
resource "aws_iam_openid_connect_provider" "github" {
  url = "https://token.actions.githubusercontent.com"

  client_id_list = [
    "sts.amazonaws.com"
  ]

  # BOTH thumbprints are REQUIRED (GitHub rotated certs)
  thumbprint_list = [
    "6938fd4d98bab03faadb97b34396831e3780aea1",
    "1c5847fa9b1330cc6742a033f7c353e1458e376a"
  ]
}

# 2. IAM Role assumed by GitHub Actions via OIDC
resource "aws_iam_role" "github_oidc_role" {
  name = "github-actions-oidc-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = "sts:AssumeRoleWithWebIdentity"

        Principal = {
          Federated = aws_iam_openid_connect_provider.github.arn
        }

        Condition = {
          StringEquals = {
            "token.actions.githubusercontent.com:aud": "sts.amazonaws.com"
          }
          StringLike = {
            # Allow ALL repos under your GitHub account (debug-safe)
            "token.actions.githubusercontent.com:sub": "repo:2004Asbah/*:*"
          }
        }
      }
    ]
  })
}

# 3. Attach permissions (admin for now; tighten later)
resource "aws_iam_role_policy_attachment" "oidc_admin" {
  role       = aws_iam_role.github_oidc_role.name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}
