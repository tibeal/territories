public class SObjectRecord {

    public static SObject newRecord(String sobjectType) {
        Schema.SObjectType objectToken =
            Schema.describeSObjects(
                new List<String>{
                    sobjectType
                }).get(0).getSObjectType();

        return objectToken.newSObject();
    }

    private SObject record;

    public SObjectRecord(String objectName) {
        this.record = SObjectRecord.newRecord(objectName);
    }

    public SObjectRecord setFieldValue(String fieldName, Object value) {
        this.record.put(fieldName, value);

        return this;
    }

    public SObjectRecord setSObjectField(String fieldName, object value) {
        return setSObjectField(fieldName, (SObject) value);
    }

    public SObjectRecord setSObjectField(String fieldName, SObject value) {
        this.record.putSObject(fieldName, value);

        return this;
    }

    public SObject getRecord() {
        return this.record;
    }
}