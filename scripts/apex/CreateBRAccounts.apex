StaticResource sr = [SELECT Id, Body FROM StaticResource WHERE Name = 'BRAccounts'];
List<Map<String,String>> accountsJSON = (List<Map<String,String>>) JSON.deserialize(sr.Body.toString(), List<Map<String,String>>.class);

Map<String, Account> accountsMap = new Map<String, Account>();
Set<String> names = new Set<String>();

Integer recLimit = OrgLimits.getMap().get('DataStorageMB').getLimit() <= 200 ? 100 : 1000;

for (Map<String,String> acc : accountsJSON) {
    accountsMap.put(
        acc.get('fake-company-name'),
        new Account(
            Name = acc.get('fake-company-name'),
            AccountNumber = acc.get('cnpj'),
            BillingCountry = 'Brazil'
        )
    );
    names.add(accountsMap.values().get(accountsMap.values().size()-1).Name);
    if (accountsMap.size() >= recLimit) break;
}

Map<String, Account> existingAccountMap = new Map<String, Account>();
List<Account> existingAccount = [SELECT Id, Name FROM Account WHERE Name IN :names];

for (Account acc : [SELECT Id, Name FROM Account WHERE Name IN :names]) {
    existingAccountMap.put(acc.Name, acc);
}

for (Account acc : accountsMap.values()) {
    if (existingAccountMap.containsKey(acc.Name)) {
        acc.Id = existingAccountMap.get(acc.Name).Id;
    }
}

upsert accountsMap.values() account.Id;
