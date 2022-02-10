public with sharing class RecordTypeFactory {

	private static Map<String, Schema.RecordTypeInfo> cache;

	public static Schema.RecordTypeInfo getRecordTypeByName(Schema.sObjectType sObjectType, String name) {
	
		String cacheKey = sObjectType.getDescribe().getName() + '_' + name;
		
		if(cache == null) cache = new Map<String, Schema.RecordTypeInfo>();
		
		if(cache.containsKey(cacheKey)) {
			system.debug('PULLED FROM CACHE');
			return cache.get(cacheKey);
		}
		
		Schema.RecordTypeInfo recordTypeInfo = sObjectType.getDescribe().getRecordTypeInfosByName().get(name);
		
		if(recordTypeInfo == null) throw new RecordTypeFactoryException('No record type for ' + sObjectType + ' named ' + name);
		
		cache.put(cacheKey, recordTypeInfo);
		return recordTypeInfo;	
		
	}
	
	/*
	public static Schema.RecordTypeInfo getRecordTypeById(Schema.sObjectType sObjectType, String id) {
	
		String cacheKey = sObjectType.getDescribe().getName() + '_' + id;
		if(cache == null) cache = new Map<String, Schema.RecordTypeInfo>();
		if(cache.containsKey(cacheKey)) return cache.get(cacheKey);
		try {
			Schema.RecordTypeInfo recordTypeInfo = sObjectType.getDescribe().getRecordTypeInfosById().get(id);
			cache.put(cacheKey, recordTypeInfo);
			return recordTypeInfo;
		}
		catch(Exception ex) {
			throw new RecordTypeFactoryException('No record type for ' + sObjectType + ' with id ' + id);
		}
	}
	*/
	
	public class RecordTypeFactoryException extends Exception {}

	public static testmethod void test() {
		
		Schema.RecordTypeInfo rt = RecordTypeFactory.getRecordTypeByName(Lead.sObjectType, 'ACM Lead');
		system.assertNotEquals(null, rt);
		
		// the second run should pull from cache
		rt = RecordTypeFactory.getRecordTypeByName(Lead.sObjectType, 'ACM Lead');
		system.assertNotEquals(null, rt);
		
		// this should fail
		try {
			rt = RecordTypeFactory.getRecordTypeByName(Lead.sObjectType, 'Bazinga');
		}
		catch(Exception ex) {
			System.Assert(ex.getMessage().contains('Bazinga'));
		}
		
	}

}