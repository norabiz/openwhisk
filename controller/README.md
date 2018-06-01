Controller
----------

# Deploying



```
kubectl -n openwhisk create cm controller.config --from-env-file=controller.env
```



```
kubectl apply -f controller.yml
```


