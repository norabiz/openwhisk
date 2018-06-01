Cluster Setup
-------------


```
kubectl apply -f namespace.yml
```


```
kubectl apply -f services.yml
```


```
kubectl -n openwhisk create cm whisk.config --from-env-file=config.env
```



```
kubectl -n openwhisk create cm whisk.runtimes --from-file=runtimes=runtimes.json
```



```
kubectl -n openwhisk create cm whisk.limits --from-env-file=limits.env
```



```
kubectl -n openwhisk create secret generic whisk.auth --from-file=system=auth.whisk.system --from-file=guest=auth.guest

```
