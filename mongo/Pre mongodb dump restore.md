**----------------------------------------DUMP--------------------------------**

mongodump --host 127.0.0.1 --port 27017 -u test -p MyPassword --authenticationDatabase testam --db testam --out testamdump



mongodump --host 127.0.0.1 --port 27017 -u test -p MyPassword --authenticationDatabase test --db test --out testdump



**----------------------------------------DUMP-POD-TO-LOCAL---------------------------------**

oc cp pre-mongodb/mongodb-0:/mongodb/testamdump ./testamdump



oc cp pre-mongodb/mongodb-0:/mongodb/testdump ./testdump



**----------------------------------------DUMP-LOCAL-TO-POD---------------------------------**

oc cp ./testamdump pre-new-mongodb/mongodb-0:/mongodb/testamdump



oc cp ./testdump pre-new-mongodb/mongodb-0:/mongodb/testdump



**----------------------------------------Replica Set---------------------------------**

mongodb-0 pod дотор орно 



sh-4.4$ mongosh



test> rs.status()

MongoServerError\[NotYetInitialized]: no replset config has been received

test> 



rs.initiate({

\_id: "rs0",

members: \[

{ \_id: 0, host: "mongodb-0.mongodb.pre-new-mongodb.svc.cluster.local:27017", priority: 2 },

{ \_id: 1, host: "mongodb-1.mongodb.pre-new-mongodb.svc.cluster.local:27017", priority: 1 },

{ \_id: 2, host: "mongodb-2.mongodb.pre-new-mongodb.svc.cluster.local:27017", priority: 0 }

]

})



OK



**----------------------------------------Create User---------------------------------**



use admin



db.createUser({

user: "admin",

pwd: "mbank2025",

roles: \[

{ role: "root", db: "admin" }

]

})



db.auth("admin","mbank2025") || mongosh -u "admin" -p "mbank2025" --authenticationDatabase admin







use test



db.createUser({

user: "test",

pwd: "MyPassword",

roles: \[

{ role: "readWrite", db: "test" }

]

})



use testam



db.createUser({

user: "test",

pwd: "MyPassword",

roles: \[

{ role: "readWrite", db: "testam" }

]

})



exit



**----------------------------------------RESTORE---------------------------------**





mongorestore --username test --password MyPassword --authenticationDatabase testam --db testam /mongodb/testamdump/testam



mongorestore --username test --password MyPassword --authenticationDatabase test --db test /mongodb/testdump/test



































































































