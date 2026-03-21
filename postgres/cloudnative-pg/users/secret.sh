# Keycloak test user creation sample

kubectl create secret generic keycloak-test-user \
  --from-literal=username=keycloak_test \
  --from-literal=password=keycloak_test -n cnpg-system

kubectl create secret generic gitlab-user \
  --from-literal=username=gitlab \
  --from-literal=password=gitlab -n cnpg-system

kubectl create secret generic onedev-test-user \
  --from-literal=username=onedev_test \
  --from-literal=password=onedev_test -n cnpg-system
