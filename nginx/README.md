Nginx
-----


   ```
   certs.sh localhost
   ```



```
kubectl -n openwhisk create secret tls nginx --cert=certs/cert.pem --key=certs/key.pem
```


```
kubectl -n openwhisk create configmap nginx --from-file=nginx.conf
```


```
kubectl apply -f nginx.yml
```

