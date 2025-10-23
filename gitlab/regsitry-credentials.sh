kubectl create secret docker-registry regcred \
    --namespace <namespace> \
    --docker-server="registry-gitlab.hello.com" 
    --docker-username="gitlab" \
    --docker-password="passowrd" \
    --docker-email="gitlab.hello.com"