COMMAND ?= "bash"

.PHONY: build
build:
	docker build -t mumoshu/heartbeat-operator:canary .

.PHONY: kuberun
kuberun:
	kubectl --namespace kube-system delete deploy heartbeat-operator-run || true
	kubectl --namespace kube-system run --tty -i --rm --image mumoshu/heartbeat-operator:canary heartbeat-operator-run --command -- $(COMMAND)

.PHONY: helmrun
helmrun:
	kubectl --namespace kube-system apply -f example/rbac.yaml
	helm upgrade --install --namespace kube-system -f example/values.yaml --set image.pullPolicy=IfNotPresent heartbeat-operator stable/heartbeat

.PHONY: dev
dev: build run
