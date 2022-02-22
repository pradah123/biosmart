FROM redis:6.2-alpine

EXPOSE 6379
CMD ["redis-server", "--appendonly", "yes"]
