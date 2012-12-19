# Follower Maze
Some good old TCP socket programming with ruby. 

Follower Maze is a TCP server that reads in events from an event source and forwards them onto appropiate user clients.

The server accepts two types of clients:

- **One** *event source*: It will send you a
stream of events which may or may not require clients to be notified
- **Many** *user clients*: Each one representing a specific user,
these wait for notifications for events which would be relevant to the
user they represent

### The Protocol
The protocol used by the clients is string-based (i.e. a `CRLF` control
character terminates each message). All strings are encoded in `UTF-8`.

The *event souce* **connects on port 9090** and will start sending
events as soon as the connection is accepted.

The many *user clients* will **connect on port 9099**. As soon
as the connection is accepted, they will send to the server the ID of
the represented user, so that the server knows which events to
inform them of. For example, once connected a *user client* may send down:
`2932\r\n`, indicating that they are representing user 2932.

After the identification is sent, the *user client* starts waiting for
events to be sent to them. Events coming from *event source* should be
sent to relevant *user clients* exactly like read, no modification is
required or allowed.

### The Events
There are five possible events. The table below describe payloads
sent by the *event source* and what they represent:

| Payload    | Sequence #| Type         | From User Id | To User Id |
|------------|-----------|--------------|--------------|------------|
|666|F|60|50 | 666       | Follow       | 60           | 50         |
|1|U|12|9    | 1         | Unfollow     | 12           | 9          |
|542532|B    | 542532    | Broadcast    | -            | -          |
|43|P|32|56  | 43        | Private Msg  | 2            | 56         |
|634|S|32    | 634       | Status Update| 32           | -          |

Using the verification program supplied, you will receive exactly 1000 events,
with sequence number from 1 to 1000. **The events will arrive out of order**.

Events may generate notifications for *user clients*. **If there is a
*user client* ** connected for them, these are the users to be
informed for different event types:

* **Follow**: Only the `To User Id` should be notified
* **Unfollow**: No clients should be notified
* **Broadcast**: All connected *user clients* should be notified
* **Private Message**: Only the `To User Id` should be notified
* **Status Update**: All current followers of the `From User ID` should be notified

If there are no *user client* connected for a user, any notifications
for them must be silently ignored. *user clients* expect to be notified of
events **in the correct order**, regardless of the order in which the
*event source* sent them.


## Solution

The server is based on an Evented/Reactor pattern allowing it to listen for connections, accept connections, read from and write to both ports all within one process, without the use of threads. The code uses no external libraries or dependencies.

### Running the code
The server can be run with the command:

  	$ rake run_server

The test suite using the JAR file can be run with the command:

  	$ rake run_test_suite
 

### Tests
A comprehensive set have rspec tests have been written to ensure all the functionality is covered and to verify that all classes are working correctly. The tests can be can be run from the root directory with the following command:
  
  	$ rspec spec

