
ENV=prod
NAMESPACE=default

install:
# --- pvc with nfs
	helm install pvc charts/pvc/ -f charts/env/$(ENV).yml -f pvc/nfs.yaml -n $(NAMESPACE)

# --- storage-tool-job
	helm install storage-tool-job charts/storage-tool-job/ -f charts/env/$(ENV).yml -f charts/env/$(ENV)/storage-tool-job.yml -n $(NAMESPACE)

# --- amqp-integration-adapter
	helm install amqp-integration-adapter charts/amqp-integration-adapter/ -f charts/env/$(ENV).yml -f charts/env/$(ENV)/amqp-integration-adapter.yml -n $(NAMESPACE)

# --- batch-adapter 
	helm install batch-adapter charts/batch-adapter/ -f charts/env/$(ENV).yml -f charts/env/$(ENV)/batch-adapter.yml -n $(NAMESPACE)

# --- db-integration-adapter
	helm install db-integration-adapter charts/db-integration-adapter/ -f charts/env/$(ENV).yml -f charts/env/$(ENV)/db-integration-adapter.yml -n $(NAMESPACE)

# --- file-integration-adapter
	helm install file-integration-adapter charts/file-integration-adapter/ -f charts/env/$(ENV).yml -f charts/env/$(ENV)/file-integration-adapter.yml -n $(NAMESPACE)

# --- plugin-integration-adapter
	helm install plugin-integration-adapter charts/plugin-integration-adapter/ -f charts/env/$(ENV).yml -f charts/env/$(ENV)/plugin-integration-adapter.yml -n default

# --- push-notifications-adapter
	helm install push-notifications-adapter charts/push-notifications-adapter/ -f charts/env/$(ENV).yml -f charts/env/$(ENV)/push-notifications-adapter.yml -n $(NAMESPACE)

# --- scheduler-adapter
	helm install scheduler-adapter charts/scheduler-adapter/ -f charts/env/$(ENV).yml -f charts/env/$(ENV)/scheduler-adapter.yml -n $(NAMESPACE)

# --- smev-http-adapter
	helm install smev-http-adapter charts/smev-http-adapter/ -f charts/env/$(ENV).yml -f charts/env/$(ENV)/smev-http-adapter.yml -n $(NAMESPACE)

# --- statistics-adapter
	helm install statistics-adapter charts/statistics-adapter/ -f charts/env/$(ENV).yml -f charts/env/$(ENV)/statistics-adapter.yml -n $(NAMESPACE)

# --- ws-integration-adapter
	helm install ws-integration-adapter charts/ws-integration-adapter/ -f charts/env/$(ENV).yml -f charts/env/$(ENV)/ws-integration-adapter.yml -n $(NAMESPACE)

# --- ui-adapter
	helm install ui-adapter charts/ui-adapter/ -f charts/env/$(ENV).yml -f charts/env/$(ENV)/ui-adapter.yml -n $(NAMESPACE)

# --- inner-integration-adapter
	helm install inner-integration-adapter charts/inner-integration-adapter/ -f charts/env/$(ENV).yml -f charts/env/$(ENV)/inner-integration-adapter.yml -n $(NAMESPACE)

# --- smev-front
	helm install smev-front charts/smev-front/ -f charts/env/$(ENV).yml -f charts/env/$(ENV)/smev-front.yml -n $(NAMESPACE)




uninstall:
	helm uninstall -n $(NAMESPACE) \
		smev-front \
		inner-integration-adapter \
		ui-adapter \
		ws-integration-adapter \
		statistics-adapter \
		smev-http-adapter \
		scheduler-adapter \
		push-notifications-adapter \
		plugin-integration-adapter \
		file-integration-adapter \
		db-integration-adapter \
		batch-adapter \
		amqp-integration-adapter \
		storage-tool-job \
		pvc 
	
	kubectl -n $(NAMESPACE) delete pvc file-integration-adapter smev-nfs-basket smev-nfs-key

