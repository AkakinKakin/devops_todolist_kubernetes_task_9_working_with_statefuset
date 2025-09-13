# How to validate the changes

## 1. Requirements
- kind
- kubectl
- docker

## 2. Deploy
Run:
```bash
chmod +x k8s/bootstrap.sh
k8s/bootstrap.sh
This will:

create a kind cluster (if not present)

create mysql namespace

create secrets and configmap (init.sql)

create headless Service and StatefulSet with 3 replicas

deploy a sample app that uses the DB secret and points to mysql-0

3. Verify StatefulSet and Pods
Check StatefulSet and pods:

bash
Copy code
kubectl -n mysql get sts
kubectl -n mysql get pods -o wide
You should see mysql-0, mysql-1, mysql-2.

Check their status:

bash
Copy code
kubectl -n mysql get pods -w
4. Inspect logs of mysql-0
bash
Copy code
kubectl -n mysql logs mysql-0
Look for lines indicating initialization or errors.

5. Exec into mysql-0 and verify DB / table
bash
Copy code
kubectl -n mysql exec -it mysql-0 -- bash
# inside pod
mysql -u root -p$MYSQL_ROOT_PASSWORD -e "SHOW DATABASES;"
mysql -u root -p$MYSQL_ROOT_PASSWORD -e "USE myapp; SHOW TABLES;"
If init.sql ran correctly you should see myapp and the users table.

6. Validate that app can connect (app pod)
Check app pod:

bash
Copy code
kubectl -n default get pods -l app=myapp
kubectl -n default logs deploy/myapp
If your app has a /health or DB-test endpoint, curl it:

bash
Copy code
kubectl -n default exec deploy/myapp -- curl -sS http://localhost:3000/health
or expose it via port-forward to your machine.

7. Troubleshooting
If a pod restarts constantly: kubectl -n mysql describe pod mysql-0 + kubectl -n mysql logs mysql-0.

Check PVCs:

bash
Copy code
kubectl -n mysql get pvc
If init.sql didn't run, confirm that /var/lib/mysql was empty on first start and that the ConfigMap was mounted. Inspect pod filesystem:

bash
Copy code
kubectl -n mysql exec -it mysql-0 -- ls -la /docker-entrypoint-initdb.d
8. Notes / Caveats
init.sql runs only when MySQL initializes an empty data directory. If you re-deploy over existing PVCs, init.sql won't re-run.

The app secret app-db-secret contains HOST set to mysql-0.mysql.mysql.svc.cluster.local. Adjust if your app and DB are in same namespace.

vbnet
Copy code

---

## Final notes / tips

- **Init behavior**: official MySQL images run `*.sql` files found in `/docker-entrypoint-initdb.d` only when the data directory is empty (i.e., first initialization). If the pods' PVCs are already initialized, your `init.sql` will not run again; you can delete PVCs (careful — data loss) to force re-initialization in a kind test cluster.
- **Pod hostnames**: StatefulSet pod `mysql-0` resolves to `mysql-0.mysql.<namespace>.svc.cluster.local`. If your app is in `default` namespace and DB is in `mysql` namespace, the FQDN must include `mysql` namespace.
- **Probes**: using `mysqladmin ping` with env vars works but ensure the user exists and has privileges. In the manifest we used `MYSQL_USER` to check liveness/readiness.
- **Storage**: `volumeClaimTemplates` will create PVCs backed by kind's storage. For production you should pick a proper StorageClass.

---

If you want, I can:
- adapt the manifests to **PostgreSQL** instead of MySQL, or to a specific MySQL/MariaDB image;  
- produce a version using `secret` with `base64` encoded data;  
- show a minimal app script (Node.js) that uses the secret env variables to connect to the DB and run a test query; or  
- commit these files into the repo structure and open a PR (tell me where to place them).  