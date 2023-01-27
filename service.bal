import ballerina/http;

public type CovidEntry record {|
    readonly string iso_code;
    string country;
    decimal cases;
    decimal deaths;
    decimal recovered;
    decimal active;
|};

public final table<CovidEntry> key(iso_code) covidTable = table [
    {iso_code: "AFG", country: "Afghanistan", cases: 159303, deaths: 7386, recovered: 146084, active: 5833},
    {iso_code: "SL", country: "Sri Lanka", cases: 598536, deaths: 15243, recovered: 568637, active: 14656},
    {iso_code: "US", country: "USA", cases: 69808350, deaths: 880976, recovered: 43892277, active: 25035097}
];

# Description
#
# + body - Field Description
public type ConflictingIsoCodesError record {|
   *http:Conflict;
   ErrorMsg body;
|};

# Description
#
# + errmsg - Error message
public type ErrorMsg record {|
   string errmsg;
|};

# Description
#
# + body - Error message
public type InvalidIsoCodeError record {|
    *http:NotFound;
    ErrorMsg body;
|};

# A service representing a network-accessible API
# bound to port `9090`.
service /covid/status on new http:Listener(9090) {

    # A resource for retrieving covid countries
    # + return - string name with covid countries
    resource function get countries() returns CovidEntry[] {
        return covidTable.toArray();
    }

    # A resource for generating greetings
    # + covidEntries - body of the http post request
    # + return - string name with entry or error
    resource function post countries(@http:Payload CovidEntry[] covidEntries)
                                    returns CovidEntry[]|ConflictingIsoCodesError {

    string[] conflictingISOs = from CovidEntry covidEntry in covidEntries
        where covidTable.hasKey(covidEntry.iso_code)
        select covidEntry.iso_code;

        if conflictingISOs.length() > 0 {
            return {
                body: {
                    errmsg: string:'join(" ", "Conflicting ISO Codes:", ...conflictingISOs)
                }
            };
        } else {
            covidEntries.forEach(covdiEntry => covidTable.add(covdiEntry));
            return covidEntries;
        }
    }

    resource function get countries/[string iso_code]() returns CovidEntry|InvalidIsoCodeError {
        CovidEntry? covidEntry = covidTable[iso_code];
        if covidEntry is () {
            return {
                body: {
                    errmsg: string `Invalid ISO Code: ${iso_code}`
                }
            };
        }
        return covidEntry;
    }

    # A resource for generating greetings
    # + name - the input string name
    # + return - string name with hello message or error
    resource function get greeting(string name) returns string|error {
        // Send a response back to the caller.
        if name is "" {
            return error("name should not be empty!");
        }
        return "Hello, " + name;
    }
}
