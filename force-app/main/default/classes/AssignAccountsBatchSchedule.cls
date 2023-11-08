public class AssignAccountsBatchSchedule implements Database.Batchable<SObject>, Database.Stateful {
    public integer brAccounts;
    public integer usAccounts;
    public integer itaAccounts;

    public Database.QueryLocator start(Database.BatchableContext BC) {
        Set<String> countries = new Set<String>{
            'Brazil',
            'Italy',
            'United States'
        };
        this.brAccounts = 0;
        this.usAccounts = 0;
        this.itaAccounts = 0;
        return Database.getQueryLocator('SELECT Id, BillingCountry FROM Account WHERE BillingCountry = :countries ORDER BY BillingCountry, NAME', AccessLevel.SYSTEM_MODE);
    }

    public void execute(Database.BatchableContext BC, List<Account> scope) {
        HelperClass helper = new HelperClass();

        List<SObject> territoriesUSBR = Database.query('SELECT Id, ParentTerritory2.ParentTerritory2Id, Name FROM Territory2 WHERE ParentTerritory2.ParentTerritory2.Name IN (\'Brazil\',\'United States of America\')');
        List<SObject> territoriesITA = Database.query('SELECT Id, ParentTerritory2.ParentTerritory2.ParentTerritory2Id, Name FROM Territory2 WHERE ParentTerritory2.ParentTerritory2.ParentTerritory2.Name IN (\'Italy\')');
        Map<Id, List<SObject>> territoriesByCountry = helper.getMapByFieldId('ParentTerritory2.ParentTerritory2Id', territoriesUSBR);
        territoriesByCountry.putAll(helper.getMapByFieldId('ParentTerritory2.ParentTerritory2.ParentTerritory2Id', territoriesITA));
        List<SObject> allTerritories = Database.query('SELECT Id, ParentTerritory2.ParentTerritory2Id, ParentTerritory2.ParentTerritory2.ParentTerritory2Id, Name FROM Territory2 WHERE Name IN (\'Brazil\',\'United States of America\',\'Italy\')');
        Map<String, SObject> territoriesByName = helper.getMapByField('Name', allTerritories);

        Integer brTerritories = territoriesByCountry.get(territoriesByName.get('Brazil').Id).size(),
        usTerritories = territoriesByCountry.get(territoriesByName.get('United States of America').Id).size(),
        itaTerritories = territoriesByCountry.get(territoriesByName.get('Italy').Id).size(),
        index;
        String territoryName;

        List<SObject> accountAssociations = new List<SObject>();
        for (Account acc : scope) {
            accountAssociations.add(
                new SObjectRecord('ObjectTerritory2Association')
                    .setFieldValue('ObjectId', acc.Id)
                    .setFieldValue('AssociationCause', 'Territory2Manual')
                    .getRecord()
            );
            if (acc.BillingCountry ==  'Brazil') {
                index = math.mod(++this.brAccounts,brTerritories);
                territoryName = acc.BillingCountry;
            } else if (acc.BillingCountry ==  'Italy') {
                index = math.mod(++this.itaAccounts,itaTerritories);
                territoryName = acc.BillingCountry;
            } else {
                index = math.mod(++this.usAccounts,usTerritories);
                territoryName = 'United States of America';
            }

            accountAssociations.get(accountAssociations.size()-1).put('Territory2Id',
                territoriesByCountry.get(territoriesByName.get(territoryName).Id).get(index).Id);
        }

        if(!accountAssociations.isEmpty()){
            Database.insert(accountAssociations, false);
        }
    }

    public void finish(Database.BatchableContext BC) {}

    public class HelperClass{
        public Map<Id, List<SObject>> getMapByFieldId(String fieldName, List<SObject> records) {

            Map<Id, List<SObject>> recordsMap = new Map<Id, List<SObject>>();
            for (Sobject record : records) {
                Id key = (Id) getFieldValue(record, fieldName);
                if (recordsMap.containsKey(key)) {
                    recordsMap.get(key).add(record);
                } else {
                    recordsMap.put(key, new List<SObject>{record});
                }
            }

            return recordsMap;
        }
        public Map<String,SObject> getMapByField(String externalIdField, List<SObject> records) {
            Map<String,SObject> recordMap = new Map<String,SObject>();

            for (SObject record : records) recordMap.put(String.valueOf(record.get(externalIdField)), record);

            return recordMap;
        }
        public Object getFieldValue(sObject record, String apiName) {
            Object value = null;
            if (apiName.contains('.')) {
                List<String> objectNameAndField = apiName.split('\\.');
                Boolean hasToLabel = apiName.contains('tolabel(') ? true : false;
                SObject currentObject = record;
                for(Integer i=0; i < objectNameAndField.size(); i++) {
                    if (currentObject == null) break;
                    if (i == objectNameAndField.size() - 1) {
                        String field = hasToLabel ? objectNameAndField[i].substringAfterLast(')').trim() : objectNameAndField[i];
                        value = currentObject.get(field);
                    } else {
                        String objName = hasToLabel ? objectNameAndField[i].removeStart('tolabel(') : objectNameAndField[i];
                        currentObject = currentObject.getSObject(objName);
                    }
                }
            } else {
                if(apiName.contains('tolabel(')){
                    //Get only the alias
                    apiName = apiName.substringAfterLast(')').trim();
                }
                value = record.get(apiName);
            }
            return value;
        }
    }
}