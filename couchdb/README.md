CouchDB
-----

# Deploying

## Create secret and configmap



```
kubectl -n openwhisk create secret generic db.auth --from-literal=db_username=whisk_admin --from-literal=db_password=some_passw0rd
```

```
kubectl -n openwhisk create configmap db.config --from-literal=db_protocol=http --from-literal=db_provider=CouchDB --from-literal=db_whisk_activations=test_activations --from-literal=db_whisk_actions=test_whisks --from-literal=db_whisk_auths=test_subjects --from-literal=db_prefix=test_
```



```
kubectl apply -f couchdb.yml
```





