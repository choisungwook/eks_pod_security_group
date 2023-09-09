up:
	cd eksctl && eksctl create cluster -f cluster.yaml
down:
	cd eksctl && eksctl delete cluster -f cluster.yaml
