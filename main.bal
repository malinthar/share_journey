import ballerina/http;
import ballerina/uuid;
import ballerinax/mongodb;

const string JOURNEY_COLLECTION = "journeys";
configurable string password = ?;
configurable string database = ?;
configurable string username = ?;

mongodb:ConnectionConfig mongoConfig = {
    connection: {url: string `mongodb+srv://${username}:${password}@fina-a-journey.ugfjnsm.mongodb.net/?retryWrites=true&w=majority`},
    databaseName: database
};

mongodb:Client mongo = check new (mongoConfig);

type Joureny record {|
    string 'start;
    string end;
    decimal cost;
    int days;
    int numOfPeople;
|};

type Trip record {|
    *Joureny;
    string tripId;
|};

type TripDocument record {|
    *Trip;
    record {} _id;
|};

service /travelbook/share on new http:Listener(9090) {
    resource function post .(@http:Payload Joureny payload) returns TripDocument|error {
        Trip trip = {tripId: uuid:createType1AsString(), ...payload};
        mongodb:Error? result = mongo->insert(trip, JOURNEY_COLLECTION);
        if result is error {
            return result;
        }
        stream<TripDocument, error?>|error findResult = mongo->find(JOURNEY_COLLECTION, filter = {tripId: trip.tripId});

        if findResult is error {
            return error("Unsuccessful!");
        }

        record {|TripDocument value;|}|error? next = findResult.next();

        if next is record {|TripDocument value;|} {
            return next.value;
        }
        return error("Unsuccessful!");
    }
}

//Three micro services 1. Data persistent service, add journey, journey serarch(calculator) 
//People can add their travel experiences
//Others can view travel experiences
//Predict price for the trip -> calculate cost for the trip and days
// docker run -d -v /home/malintha/Documents/wso2/ballerina/travelbook/travelbook-share/Config.toml:/home/ballerina/Config.toml -p 9090:9090  --add-host=mongoservice:172.17.0.1 malintha1996/travelbook_share:v0.1.0

