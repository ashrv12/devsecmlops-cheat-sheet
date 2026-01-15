# remove everything that is unused (DANGEROUS)
docker system prune -a

# remove everything that is unused (safe)
docker system prune

# remove unused docker volumes
docker volume prune

# remove all volumes (DANGEROUS)
docker volume prune -a
