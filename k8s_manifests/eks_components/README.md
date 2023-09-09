# 개요
* EKS 컴퍼넌트 설치 가이드
* 컴퍼넌트 목록
  * ALB controller
  * External DNS controller

# 전제조건
* OIDC provider 설치
```bash
CLUSTER_NAME="securitygroup-for-pod"
eksctl utils associate-iam-oidc-provider --cluster ${CLUSTER_NAME} --approve
```

* route53에 hostzone 등록되어 있어야 함

# ALB controller
```bash
CLUSTER_NAME="securitygroup-for-pod"

# IAM policy 생성
aws iam create-policy --policy-name "AWSLoadBalancerControllerIAMPolicy" --policy-document file://alb_controller_policy.json

# IRSA
POLICY_ARN=$(aws iam list-policies --query 'Policies[?PolicyName==`AWSLoadBalancerControllerIAMPolicy`].Arn' --output text)
ROLE_NAME="AmazonEKSLoadBalancerControllerRole"
eksctl create iamserviceaccount \
  --cluster ${CLUSTER_NAME} \
  --namespace=kube-system \
  --name=aws-load-balancer-controller \
  --role-name ${ROLE_NAME} \
  --attach-policy-arn=${POLICY_ARN} \
  --approve

# helm release
helm upgrade --install aws-load-balancer-controller eks/aws-load-balancer-controller \
  -n kube-system \
  --set clusterName=${CLUSTER_NAME} \
  --set serviceAccount.create=false \
  --set serviceAccount.name=aws-load-balancer-controller
```

# DNS 컨트롤러
```bash
CLUSTER_NAME="securitygroup-for-pod"
EXTERNALDNS_NS="externaldns"

# IAM policy 추가
aws iam create-policy --policy-name "AllowExternalDNSUpdates" --policy-document file://external_dns_controller_policy.json

# namespace 추가
kubectl create namespace $EXTERNALDNS_NS

# IRSA 생성
POLICY_ARN=$(aws iam list-policies --query 'Policies[?PolicyName==`AllowExternalDNSUpdates`].Arn' --output text)
eksctl create iamserviceaccount \
  --cluster $CLUSTER_NAME \
  --name "external-dns" \
  --namespace ${EXTERNALDNS_NS} \
  --attach-policy-arn $POLICY_ARN \
  --approve \
  --override-existing-serviceaccounts

# manifest 생성
kubectl apply -f external-dns-controller.yaml
```

# 삭제 방법
```bash
kubectl delete -f external-dns-controller.yaml
helm -n kube-system uninstall aws-load-balancer-controller
```
