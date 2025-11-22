/**
 * @description Tests for the rflib_SOQL class.
 * Copyright (c) 2025 Beyond The Cloud Sp. z o.o. (BeyondTheCloud.Dev)
 * Licensed under the MIT License (https://github.com/beyond-the-cloud-dev/soql-lib/blob/main/LICENSE)
 *
 * v6.5.0
 *
 * PMD False Positives:
 * - CyclomaticComplexity: It is a library and we tried to put everything into ONE test class
 * - CognitiveComplexity: It is a library and we tried to put everything into ONE test class
 * - NcssTypeCount: It is a library and we tried to put everything into ONE test class
**/
@SuppressWarnings('PMD.CyclomaticComplexity,PMD.CognitiveComplexity,PMD.NcssTypeCount')
@IsTest
private class rflib_SOQL_Test {
	@IsTest
	static void ofSObjectType() {
		// Test
		String soql = rflib_SOQL.of(Account.SObjectType).toString();

		// Verify
		Assert.areEqual('SELECT Id FROM Account', soql, 'The generated rflib_SOQL should match the expected one.');
	}

	@IsTest
	static void ofString() {
		// Test
		String soql = rflib_SOQL.of('Account').toString();

		// Verify
		Assert.areEqual('SELECT Id FROM Account', soql, 'The generated rflib_SOQL should match the expected one.');
	}

	@IsTest
	static void count() {
		// Test
		String soql = rflib_SOQL.of(Account.SObjectType).count().toString();

		// Verify
		Assert.areEqual('SELECT COUNT() FROM Account', soql, 'The generated rflib_SOQL should match the expected one.');
	}

	@IsTest
	static void countWithDefaultFields() {
		// Test
		String soql = rflib_SOQL.of(Account.SObjectType)
			.with(Account.Id, Account.Name)
			.count()
			.toString();

		// Verify
		Assert.areEqual('SELECT COUNT() FROM Account', soql, 'The generated rflib_SOQL should match the expected one.');
	}

	@IsTest
	static void countSObjectField() {
		// Test
		String soql = rflib_SOQL.of(Opportunity.SObjectType)
			.count(Opportunity.Id)
			.count(Opportunity.CampaignId)
			.toString();

		// Verify
		Assert.areEqual('SELECT COUNT(Id), COUNT(CampaignId) FROM Opportunity', soql, 'The generated rflib_SOQL should match the expected one.');
	}

	@IsTest
	static void countSObjectFieldWithDefaultFields() {
		// Test
		String soql = rflib_SOQL.of(Opportunity.SObjectType)
			.with(Opportunity.LeadSource)
			.count(Opportunity.Id)
			.count(Opportunity.CampaignId)
			.toString();

		// Verify
		Assert.areEqual('SELECT COUNT(Id), COUNT(CampaignId) FROM Opportunity', soql, 'The generated rflib_SOQL should match the expected one.');
	}

	@IsTest
	static void countWithAlias() {
		// Test
		String soql = rflib_SOQL.of(Account.SObjectType).count(Account.Name, 'names').toString();

		// Verify
		Assert.areEqual('SELECT COUNT(Name) names FROM Account', soql, 'The generated rflib_SOQL should match the expected one.');
	}

	@IsTest
	static void countRelated() {
		// Test
		String soql = rflib_SOQL.of(Contact.SObjectType)
			.count('Account', Account.Name)
			.toString();

		// Verify
		Assert.areEqual('SELECT COUNT(Account.Name) FROM Contact', soql, 'The generated rflib_SOQL should match the expected one.');
	}

	@IsTest
	static void countRelatedWithAlias() {
		// Test
		String soql = rflib_SOQL.of(Contact.SObjectType)
			.count('Account', Account.Name, 'names')
			.toString();

		// Verify
		Assert.areEqual('SELECT COUNT(Account.Name) names FROM Contact', soql, 'The generated rflib_SOQL should match the expected one.');
	}

	@IsTest
	static void avg() {
		// Test
		String soql = rflib_SOQL.of(Opportunity.SObjectType)
			.with(Opportunity.CampaignId)
			.avg(Opportunity.Amount)
			.groupBy(Opportunity.CampaignId)
			.toString();

		// Verify
		Assert.areEqual('SELECT CampaignId, AVG(Amount) FROM Opportunity GROUP BY CampaignId', soql, 'The generated rflib_SOQL should match the expected one.');
	}

	@IsTest
	static void avgWithAlias() {
		// Test
		String soql = rflib_SOQL.of(Opportunity.SObjectType)
			.with(Opportunity.CampaignId)
			.avg(Opportunity.Amount, 'amount')
			.groupBy(Opportunity.CampaignId)
			.toString();

		// Verify
		Assert.areEqual('SELECT CampaignId, AVG(Amount) amount FROM Opportunity GROUP BY CampaignId', soql, 'The generated rflib_SOQL should match the expected one.');
	}

	@IsTest
	static void avgRelated() {
		// Test
		String soql = rflib_SOQL.of(OpportunityLineItem.SObjectType)
			.avg('Opportunity', Opportunity.Amount)
			.toString();

		// Verify
		Assert.areEqual('SELECT AVG(Opportunity.Amount) FROM OpportunityLineItem', soql, 'The generated rflib_SOQL should match the expected one.');
	}

	@IsTest
	static void avgRelatedWithAlias() {
		// Test
		String soql = rflib_SOQL.of(OpportunityLineItem.SObjectType)
			.avg('Opportunity', Opportunity.Amount, 'amount')
			.toString();

		// Verify
		Assert.areEqual('SELECT AVG(Opportunity.Amount) amount FROM OpportunityLineItem', soql, 'The generated rflib_SOQL should match the expected one.');
	}

	@IsTest
	static void countDistinct() {
		// Test
		String soql = rflib_SOQL.of(Lead.SObjectType).countDistinct(Lead.Company).toString();

		// Verify
		Assert.areEqual('SELECT COUNT_DISTINCT(Company) FROM Lead', soql, 'The generated rflib_SOQL should match the expected one.');
	}

	@IsTest
	static void countDistinctWithAlias() {
		// Test
		String soql = rflib_SOQL.of(CampaignMember.SObjectType)
			.countDistinct('Lead', Lead.Company)
			.toString();

		// Verify
		Assert.areEqual('SELECT COUNT_DISTINCT(Lead.Company) FROM CampaignMember', soql, 'The generated rflib_SOQL should match the expected one.');
	}

	@IsTest
	static void countDistinctRelated() {
		// Test
		String soql = rflib_SOQL.of(CampaignMember.SObjectType)
			.countDistinct('Lead', Lead.Company, 'company')
			.toString();

		// Verify
		Assert.areEqual('SELECT COUNT_DISTINCT(Lead.Company) company FROM CampaignMember', soql, 'The generated rflib_SOQL should match the expected one.');
	}

	@IsTest
	static void countDistinctRelatedWithAlias() {
		// Test
		String soql = rflib_SOQL.of(Lead.SObjectType).countDistinct(Lead.Company, 'company').toString();

		// Verify
		Assert.areEqual('SELECT COUNT_DISTINCT(Company) company FROM Lead', soql, 'The generated rflib_SOQL should match the expected one.');
	}

	@IsTest
	static void min() {
		// Test
		String soql = rflib_SOQL.of(Contact.SObjectType)
			.with(Contact.FirstName, Contact.LastName)
			.min(Contact.CreatedDate)
			.groupBy(Contact.FirstName)
			.groupBy(Contact.LastName)
			.toString();

		// Verify
		Assert.areEqual(
			'SELECT FirstName, LastName, MIN(CreatedDate) FROM Contact GROUP BY FirstName, LastName',
			soql,
			'The generated rflib_SOQL should match the expected one.'
		);
	}

	@IsTest
	static void minWithAlias() {
		// Test
		String soql = rflib_SOQL.of(Contact.SObjectType)
			.with(Contact.FirstName, Contact.LastName)
			.min(Contact.CreatedDate, 'createdDate')
			.groupBy(Contact.FirstName)
			.groupBy(Contact.LastName)
			.toString();

		// Verify
		Assert.areEqual(
			'SELECT FirstName, LastName, MIN(CreatedDate) createdDate FROM Contact GROUP BY FirstName, LastName',
			soql,
			'The generated rflib_SOQL should match the expected one.'
		);
	}

	@IsTest
	static void minRelated() {
		// Test
		String soql = rflib_SOQL.of(Contact.SObjectType)
			.min('Account', Account.CreatedDate)
			.toString();

		// Verify
		Assert.areEqual('SELECT MIN(Account.CreatedDate) FROM Contact', soql, 'The generated rflib_SOQL should match the expected one.');
	}

	@IsTest
	static void minRelatedWithAlias() {
		// Test
		String soql = rflib_SOQL.of(Contact.SObjectType)
			.min('Account', Account.CreatedDate, 'createdDate')
			.toString();

		// Verify
		Assert.areEqual('SELECT MIN(Account.CreatedDate) createdDate FROM Contact', soql, 'The generated rflib_SOQL should match the expected one.');
	}

	@IsTest
	static void max() {
		// Test
		String soql = rflib_SOQL.of(Campaign.SObjectType)
			.with(Campaign.Name)
			.max(Campaign.BudgetedCost)
			.groupBy(Campaign.Name)
			.toString();

		// Verify
		Assert.areEqual('SELECT Name, MAX(BudgetedCost) FROM Campaign GROUP BY Name', soql, 'The generated rflib_SOQL should match the expected one.');
	}

	@IsTest
	static void maxWithAlias() {
		// Test
		String soql = rflib_SOQL.of(Campaign.SObjectType)
			.with(Campaign.Name)
			.max(Campaign.BudgetedCost, 'budgetedCost')
			.groupBy(Campaign.Name)
			.toString();

		// Verify
		Assert.areEqual('SELECT Name, MAX(BudgetedCost) budgetedCost FROM Campaign GROUP BY Name', soql, 'The generated rflib_SOQL should match the expected one.');
	}

	@IsTest
	static void maxRelated() {
		// Test
		String soql = rflib_SOQL.of(CampaignMember.SObjectType)
			.max('Campaign', Campaign.BudgetedCost)
			.toString();

		// Verify
		Assert.areEqual('SELECT MAX(Campaign.BudgetedCost) FROM CampaignMember', soql, 'The generated rflib_SOQL should match the expected one.');
	}

	@IsTest
	static void maxRelatedAlias() {
		// Test
		String soql = rflib_SOQL.of(CampaignMember.SObjectType)
			.max('Campaign', Campaign.BudgetedCost, 'budgetedCost')
			.toString();

		// Verify
		Assert.areEqual('SELECT MAX(Campaign.BudgetedCost) budgetedCost FROM CampaignMember', soql, 'The generated rflib_SOQL should match the expected one.');
	}

	@IsTest
	static void sum() {
		// Test
		String soql = rflib_SOQL.of(Opportunity.SObjectType).sum(Opportunity.Amount).toString();

		// Verify
		Assert.areEqual('SELECT SUM(Amount) FROM Opportunity', soql, 'The generated rflib_SOQL should match the expected one.');
	}

	@IsTest
	static void sumWithAlias() {
		// Test
		String soql = rflib_SOQL.of(Opportunity.SObjectType).sum(Opportunity.Amount, 'amount').toString();

		// Verify
		Assert.areEqual('SELECT SUM(Amount) amount FROM Opportunity', soql, 'The generated rflib_SOQL should match the expected one.');
	}

	@IsTest
	static void sumRelated() {
		// Test
		String soql = rflib_SOQL.of(OpportunityLineItem.SObjectType)
			.sum('Opportunity', Opportunity.Amount)
			.toString();

		// Verify
		Assert.areEqual('SELECT SUM(Opportunity.Amount) FROM OpportunityLineItem', soql, 'The generated rflib_SOQL should match the expected one.');
	}

	@IsTest
	static void sumRelatedWithAlias() {
		// Test
		String soql = rflib_SOQL.of(OpportunityLineItem.SObjectType)
			.sum('Opportunity', Opportunity.Amount, 'amount')
			.toString();

		// Verify
		Assert.areEqual('SELECT SUM(Opportunity.Amount) amount FROM OpportunityLineItem', soql, 'The generated rflib_SOQL should match the expected one.');
	}

	@IsTest
	static void grouping() {
		// Test
		String soql = rflib_SOQL.of(Lead.SObjectType)
			.with(Lead.LeadSource, Lead.Rating)
			.grouping(Lead.LeadSource, 'grpLS')
			.grouping(Lead.Rating, 'grpRating')
			.count(Lead.Name, 'cnt')
			.groupByRollup(Lead.LeadSource)
			.groupByRollup(Lead.Rating)
			.toString();

		// Verify
		Assert.areEqual(
			'SELECT LeadSource, Rating, GROUPING(LeadSource) grpLS, GROUPING(Rating) grpRating, COUNT(Name) cnt FROM Lead GROUP BY ROLLUP(LeadSource, Rating)',
			soql,
			'The generated rflib_SOQL should match the expected one.'
		);
	}

	@IsTest
	static void toLabelWithSObjectField() {
		// Test
		String soql = rflib_SOQL.of(Lead.SObjectType)
			.with(Lead.Company)
			.toLabel(Lead.Status)
			.toString();

		// Verify
		Assert.areEqual('SELECT Company, toLabel(Status) FROM Lead', soql, 'The generated rflib_SOQL should match the expected one.');
	}

	@IsTest
	static void toLabelWithStringField() {
		// Test
		String soql = rflib_SOQL.of(Lead.SObjectType)
			.with(Lead.Company)
			.toLabel('RecordType.Name')
			.toString();

		// Verify
		Assert.areEqual('SELECT Company, toLabel(RecordType.Name) FROM Lead', soql, 'The generated rflib_SOQL should match the expected one.');
	}

	@IsTest
	static void toLabelWithSObjectFieldAndAlias() {
		// Test
		String soql = rflib_SOQL.of(Lead.SObjectType)
			.with(Lead.Company)
			.toLabel(Lead.Status, 'leadStatus')
			.toString();

		// Verify
		Assert.areEqual('SELECT Company, toLabel(Status) leadStatus FROM Lead', soql, 'The generated rflib_SOQL should match the expected one.');
	}

	@IsTest
	static void toLabelWithStringFieldAndAlias() {
		// Test
		String soql = rflib_SOQL.of(Lead.SObjectType)
			.with(Lead.Company)
			.toLabel('RecordType.Name', 'recordTypeName')
			.toString();

		// Verify
		Assert.areEqual('SELECT Company, toLabel(RecordType.Name) recordTypeName FROM Lead', soql, 'The generated rflib_SOQL should match the expected one.');
	}

	@IsTest
	static void withStringDateFunction() {
		// Test
		String soql = rflib_SOQL.of(Lead.SObjectType)
			.with('CALENDAR_YEAR(CloseDate)')
			.groupBy('CALENDAR_YEAR(CloseDate)')
			.toString();

		// Verify
		Assert.areEqual('SELECT CALENDAR_YEAR(CloseDate) FROM Lead GROUP BY CALENDAR_YEAR(CloseDate)', soql, 'The generated rflib_SOQL should match the expected one.');
	}

	@IsTest
	static void toLabelWithAliasAndDuplicatedFields() {
		// Test
		String soql = rflib_SOQL.of(Lead.SObjectType)
			.with(Lead.Company, Lead.Status)
			.toLabel(Lead.Status, 'leadStatus')
			.toString();

		// Verify
		Assert.areEqual('SELECT Company, Status, toLabel(Status) leadStatus FROM Lead', soql, 'The generated rflib_SOQL should match the expected one.');
	}

	@IsTest
	static void formatWithSObjectField() {
		// Test
		String soql = rflib_SOQL.of(Opportunity.SObjectType)
			.format(Opportunity.Amount)
			.toString();

		// Verify
		Assert.areEqual('SELECT FORMAT(Amount) FROM Opportunity', soql, 'The generated rflib_SOQL should match the expected one.');
	}

	@IsTest
	static void formatWithAlias() {
		// Test
		String soql = rflib_SOQL.of(Opportunity.SObjectType)
			.format(Opportunity.Amount, 'amt')
			.toString();

		// Verify
		Assert.areEqual('SELECT FORMAT(Amount) amt FROM Opportunity', soql, 'The generated rflib_SOQL should match the expected one.');
	}

	@IsTest
	static void withSObjectField() {
		// Test
		String soql = rflib_SOQL.of(Account.SObjectType)
			.with(Account.Name)
			.with(Account.BillingCity)
			.toString();

		// Verify
		Assert.areEqual('SELECT Name, BillingCity FROM Account', soql, 'The generated rflib_SOQL should match the expected one.');
	}

	@IsTest
	static void withTwoSObjectFields() {
		// Test
		String soql = rflib_SOQL.of(Account.SObjectType)
			.with(Account.Name, Account.BillingCity)
			.toString();

		// Verify
		Assert.areEqual('SELECT Name, BillingCity FROM Account', soql, 'The generated rflib_SOQL should match the expected one.');
	}

	@IsTest
	static void withThreeSObjectFields() {
		// Test
		String soql = rflib_SOQL.of(Account.SObjectType)
			.with(Account.Id, Account.Name, Account.BillingCity)
			.toString();

		// Verify
		Assert.areEqual('SELECT Id, Name, BillingCity FROM Account', soql, 'The generated rflib_SOQL should match the expected one.');
	}

	@IsTest
	static void withFourSObjectFields() {
		// Test
		String soql = rflib_SOQL.of(Account.SObjectType)
			.with(Account.Id, Account.Name, Account.BillingCity, Account.AccountNumber)
			.toString();

		// Verify
		Assert.areEqual('SELECT Id, Name, BillingCity, AccountNumber FROM Account', soql, 'The generated rflib_SOQL should match the expected one.');
	}

	@IsTest
	static void withFiveSObjectFields() {
		// Test
		String soql = rflib_SOQL.of(Account.SObjectType)
			.with(Account.Id, Account.Name, Account.BillingCity, Account.AccountNumber, Account.AccountSource)
			.toString();

		// Verify
		Assert.areEqual('SELECT Id, Name, BillingCity, AccountNumber, AccountSource FROM Account', soql, 'The generated rflib_SOQL should match the expected one.');
	}

	@IsTest
	static void withListOfSObjectFields() {
		// Test
		String soql = rflib_SOQL.of(Account.SObjectType)
			.with(new List<SObjectField>{
				Account.Id,
				Account.Name,
				Account.Industry,
				Account.AccountNumber,
				Account.AnnualRevenue,
				Account.BillingCity
			}).toString();

		// Verify
		Assert.areEqual('SELECT Id, Name, Industry, AccountNumber, AnnualRevenue, BillingCity FROM Account', soql, 'The generated rflib_SOQL should match the expected one.');
	}

	@IsTest
	static void withListOfStringFields() {
		// Test
		String soql = rflib_SOQL.of(Account.SObjectType)
			.with(new List<String>{
				'Id',
				'Name',
				'Industry',
				'AccountNumber',
				'AnnualRevenue',
				'BillingCity'
			}).toString();

		// Verify
		Assert.areEqual('SELECT Id, Name, Industry, AccountNumber, AnnualRevenue, BillingCity FROM Account', soql, 'The generated rflib_SOQL should match the expected one.');
	}

	@IsTest
	static void withStringFields() {
		// Test
		String soql = rflib_SOQL.of(Account.SObjectType)
			.with('Id, Name, BillingCity')
			.toString();

		// Verify
		Assert.areEqual('SELECT Id, Name, BillingCity FROM Account', soql, 'The generated rflib_SOQL should match the expected one.');
	}

	@IsTest
	static void withStringAggregationAndGroupingFields() {
		// Test
		String soql = rflib_SOQL.of(Opportunity.SObjectType)
			.with('CampaignId campaign, AVG(Amount) amount')
			.groupBy(Opportunity.CampaignId)
			.toString();

		// Verify
		Assert.areEqual('SELECT CampaignId campaign, AVG(Amount) amount FROM Opportunity GROUP BY CampaignId', soql, 'The generated rflib_SOQL should match the expected one.');
	}

	@IsTest
	static void withStringFieldsAndToLabelFunction() {
		// Test
		String soql = rflib_SOQL.of(Case.SObjectType)
			.with('Id, toLabel(Status), Subject')
			.toString();

		// Verify
		Assert.areEqual('SELECT Id, Subject, toLabel(Status) FROM Case', soql, 'The generated rflib_SOQL should match the expected one.');
	}

	@IsTest
	static void withFieldAlias() {
		// Test
		String soql = rflib_SOQL.of(Account.SObjectType)
			.with(Account.Name, 'myAlias')
			.groupBy(Account.Name)
			.toString();

		// Verify
		Assert.areEqual('SELECT Name myAlias FROM Account GROUP BY Name', soql, 'The generated rflib_SOQL should match the expected one.');
	}

	@IsTest
	static void withDuplicatedFields() {
		// Test
		String soql = rflib_SOQL.of(Account.SObjectType)
			.with('Id, Name, BillingCity')
			.with(Account.Id, Account.Name)
			.toString();

		// Verify
		Assert.areEqual('SELECT Id, Name, BillingCity FROM Account', soql, 'The generated rflib_SOQL should match the expected one.');
	}

	@IsTest
	static void withRelatedField() {
		// Test
		String soql = rflib_SOQL.of(Account.SObjectType)
			.with(Account.Name, Account.BillingCity)
			.with('CreatedBy', User.Name)
			.toString();

		// Verify
		Assert.areEqual('SELECT Name, BillingCity, CreatedBy.Name FROM Account', soql, 'The generated rflib_SOQL should match the expected one.');
	}

	@IsTest
	static void withTwoRelatedFields() {
		// Test
		String soql = rflib_SOQL.of(Account.SObjectType)
			.with(Account.Name, Account.BillingCity)
			.with('CreatedBy', User.Id, User.Name)
			.toString();

		// Verify
		Assert.areEqual('SELECT Name, BillingCity, CreatedBy.Id, CreatedBy.Name FROM Account', soql, 'The generated rflib_SOQL should match the expected one.');
	}

	@IsTest
	static void withThreeRelatedFields() {
		// Test
		String soql = rflib_SOQL.of(Account.SObjectType)
			.with(Account.Name, Account.BillingCity)
			.with('CreatedBy', User.Id, User.Name, User.Alias)
			.toString();

		// Verify
		Assert.areEqual('SELECT Name, BillingCity, CreatedBy.Id, CreatedBy.Name, CreatedBy.Alias FROM Account', soql, 'The generated rflib_SOQL should match the expected one.');
	}

	@IsTest
	static void withFourRelatedFields() {
		// Test
		String soql = rflib_SOQL.of(Account.SObjectType)
			.with(Account.Name, Account.BillingCity)
			.with('CreatedBy', User.Id, User.Name, User.Alias, User.City)
			.toString();

		// Verify
		Assert.areEqual('SELECT Name, BillingCity, CreatedBy.Id, CreatedBy.Name, CreatedBy.Alias, CreatedBy.City FROM Account', soql, 'The generated rflib_SOQL should match the expected one.');
	}

	@IsTest
	static void withFiveRelatedFields() {
		// Test
		String soql = rflib_SOQL.of(Account.SObjectType)
			.with(Account.Name, Account.BillingCity)
			.with('CreatedBy', User.Id, User.Name, User.Alias, User.City, User.CompanyName)
			.toString();

		// Verify
		Assert.areEqual('SELECT Name, BillingCity, CreatedBy.Id, CreatedBy.Name, CreatedBy.Alias, CreatedBy.City, CreatedBy.CompanyName FROM Account', soql, 'The generated rflib_SOQL should match the expected one.');
	}

	@IsTest
	static void withRelatedFields() {
		// Test
		String soql = rflib_SOQL.of(Account.SObjectType)
			.with(Account.Name, Account.BillingCity)
			.with('CreatedBy', new List<SObjectField>{
				User.Id, User.Name
			}).toString();

		// Verify
		Assert.areEqual('SELECT Name, BillingCity, CreatedBy.Id, CreatedBy.Name FROM Account', soql, 'The generated rflib_SOQL should match the expected one.');
	}

	@IsTest
	static void subQueryField() {
		// Test
		String soql = rflib_SOQL.of(Account.SObjectType)
			.with(Account.Name)
			.with(rflib_SOQL.SubQuery.of('Contacts')
				.with(Contact.Id)
			).toString();

		// Verify
		Assert.areEqual('SELECT Name , (SELECT Id FROM Contacts) FROM Account', soql, 'The generated rflib_SOQL should match the expected one.');
	}

	@IsTest
	static void withFieldSetException() {
		 // Setup
		 Exception queryException = null;

		 // Test
		 try {
			rflib_SOQL.of(Account.SObjectType)
				.withFieldSet('FieldSetName')
				.toString();
		 } catch(Exception e) {
			 queryException = e;
		 }

		// Verify
		Assert.areEqual('FieldSet with name FieldSetName does not exist!', queryException.getMessage(), 'The exception message should match the expected one.');
	}

	@IsTest
	static void subQueryTwoFields() {
		// Test
		String soql = rflib_SOQL.of(Account.SObjectType)
			.with(Account.Name)
			.with(rflib_SOQL.SubQuery.of('Contacts')
				.with(Contact.Id, Contact.Name)
			).toString();

		// Verify
		Assert.areEqual('SELECT Name , (SELECT Id, Name FROM Contacts) FROM Account', soql, 'The generated rflib_SOQL should match the expected one.');
	}

	@IsTest
	static void subQueryThreeFields() {
		// Test
		String soql = rflib_SOQL.of(Account.SObjectType)
			.with(Account.Name)
			.with(rflib_SOQL.SubQuery.of('Contacts')
				.with(Contact.Id, Contact.Name, Contact.AccountId)
			).toString();

		// Verify
		Assert.areEqual('SELECT Name , (SELECT Id, Name, AccountId FROM Contacts) FROM Account', soql, 'The generated rflib_SOQL should match the expected one.');
	}

	@IsTest
	static void subQueryFourFields() {
		// Test
		String soql = rflib_SOQL.of(Account.SObjectType)
			.with(Account.Name)
			.with(rflib_SOQL.SubQuery.of('Contacts')
				.with(Contact.Id, Contact.Name, Contact.AccountId, Contact.Email)
			).toString();

		// Verify
		Assert.areEqual('SELECT Name , (SELECT Id, Name, AccountId, Email FROM Contacts) FROM Account', soql, 'The generated rflib_SOQL should match the expected one.');
	}

	@IsTest
	static void subQueryFiveFields() {
		// Test
		String soql = rflib_SOQL.of(Account.SObjectType)
			.with(Account.Name)
			.with(rflib_SOQL.SubQuery.of('Contacts')
				.with(Contact.Id, Contact.Name, Contact.AccountId, Contact.Email, Contact.Phone)
			).toString();

		// Verify
		Assert.areEqual('SELECT Name , (SELECT Id, Name, AccountId, Email, Phone FROM Contacts) FROM Account', soql, 'The generated rflib_SOQL should match the expected one.');
	}

	@IsTest
	static void subQueryFields() {
		// Test
		String soql = rflib_SOQL.of(Account.SObjectType)
			.with(Account.Name)
			.with(rflib_SOQL.SubQuery.of('Contacts')
				.with(new List<SObjectField>{
					Contact.Id, Contact.Name
				})
			).toString();

		// Verify
		Assert.areEqual('SELECT Name , (SELECT Id, Name FROM Contacts) FROM Account', soql, 'The generated rflib_SOQL should match the expected one.');
	}

	@IsTest
	static void subQueryStringFields() {
		// Test
		String soql = rflib_SOQL.of(Account.SObjectType)
			.with(Account.Name)
			.with(rflib_SOQL.SubQuery.of('Contacts')
				.with('Id, Name')
			).toString();

		// Verify
		Assert.areEqual('SELECT Name , (SELECT Id, Name FROM Contacts) FROM Account', soql, 'The generated rflib_SOQL should match the expected one.');
	}

	@IsTest
	static void subQueryRelatedFields() {
		// Test
		String soql = rflib_SOQL.of(Account.SObjectType)
			.with(Account.Name)
			.with(rflib_SOQL.SubQuery.of('Contacts')
				.with(Contact.Id, Contact.Name)
				.with('CreatedBy', new List<SObjectField>{
					User.Id, User.Name
				})
			).toString();

		// Verify
		Assert.areEqual('SELECT Name , (SELECT Id, Name, CreatedBy.Id, CreatedBy.Name FROM Contacts) FROM Account', soql, 'The generated rflib_SOQL should match the expected one.');
	}

	@IsTest
	static void subQueryTwoLevels() {
		// Test
		String soql = rflib_SOQL.of(Account.SObjectType)
			.with(Account.Name)
			.with(rflib_SOQL.SubQuery.of('Contacts')
				.with(Contact.LastName)
				.with(rflib_SOQL.SubQuery.of('Assets').with(Asset.AssetLevel))
			)
			.toString();

		// Verify
		Assert.areEqual('SELECT Name , (SELECT LastName , (SELECT AssetLevel FROM Assets) FROM Contacts) FROM Account', soql, 'The generated rflib_SOQL should match the expected one.');
	}

	@IsTest
	static void subQueryWhereFilterGroup() {
		// Test
		String soql = rflib_SOQL.of(Account.SObjectType)
			.with(Account.Name)
			.with(rflib_SOQL.SubQuery.of('Contacts')
				.with(Contact.Id, Contact.Name)
				.whereAre(rflib_SOQL.FilterGroup
					.add(rflib_SOQL.Filter.with(Contact.LastName).equal('Doe'))
				)
			).toString();

		// Verify
		Assert.areEqual('SELECT Name , (SELECT Id, Name FROM Contacts WHERE (LastName = :v1)) FROM Account', soql, 'The generated rflib_SOQL should match the expected one.');
	}

	@IsTest
	static void subQueryWhereFilter() {
		// Test
		String soql = rflib_SOQL.of(Account.SObjectType)
			.with(Account.Name)
			.with(rflib_SOQL.SubQuery.of('Contacts')
				.with(Contact.Id, Contact.Name)
				.whereAre(rflib_SOQL.Filter.with(Contact.LastName).equal('Doe'))
			).toString();

		// Verify
		Assert.areEqual('SELECT Name , (SELECT Id, Name FROM Contacts WHERE LastName = :v1) FROM Account', soql, 'The generated rflib_SOQL should match the expected one.');
	}

	@IsTest
	static void subQueryOrderBySObjectField() {
		// Test
		String soql = rflib_SOQL.of(Account.SObjectType)
			.with(Account.Name)
			.with(rflib_SOQL.SubQuery.of('Contacts')
				.with(Contact.Id, Contact.Name)
				.orderBy(Contact.Name)
				.sortDesc()
				.nullsLast()
			).toString();

		// Verify
		Assert.areEqual('SELECT Name , (SELECT Id, Name FROM Contacts ORDER BY Name DESC NULLS LAST) FROM Account', soql, 'The generated rflib_SOQL should match the expected one.');
	}

	@IsTest
	static void subQueryOrderByStringField() {
		// Test
		String soql = rflib_SOQL.of(Account.SObjectType)
			.with(Account.Name)
			.with(rflib_SOQL.SubQuery.of('Contacts')
				.with(Contact.Id, Contact.Name)
				.orderBy('Name')
				.sortDesc()
				.nullsLast()
			).toString();

		// Verify
		Assert.areEqual('SELECT Name , (SELECT Id, Name FROM Contacts ORDER BY Name DESC NULLS LAST) FROM Account', soql, 'The generated rflib_SOQL should match the expected one.');
	}

	@IsTest
	static void subQueryOrderByDynamic() {
		// Test
		String soql = rflib_SOQL.of(Account.SObjectType)
			.with(Account.Name)
			.with(rflib_SOQL.SubQuery.of('Contacts')
				.with(Contact.Id, Contact.Name)
				.orderBy('Name')
				.sort('ASC')
				.nullsLast()
			).toString();

		// Verify
		Assert.areEqual('SELECT Name , (SELECT Id, Name FROM Contacts ORDER BY Name ASC NULLS LAST) FROM Account', soql, 'The generated rflib_SOQL should match the expected one.');
	}

	@IsTest
	static void subQueryOrderByRelated() {
		// Test
		String soql = rflib_SOQL.of(Account.SObjectType)
			.with(Account.Name)
			.with(rflib_SOQL.SubQuery.of('Contacts')
				.with(Contact.Id, Contact.Name)
				.orderBy('CreatedBy', User.Name)
				.sortDesc()
				.nullsLast()
			).toString();

		// Verify
		Assert.areEqual('SELECT Name , (SELECT Id, Name FROM Contacts ORDER BY CreatedBy.Name DESC NULLS LAST) FROM Account', soql, 'The generated rflib_SOQL should match the expected one.');
	}

	@IsTest
	static void subQuerySetLimit() {
		// Test
		String soql = rflib_SOQL.of(Account.SObjectType)
			.with(Account.Name)
			.with(rflib_SOQL.SubQuery.of('Contacts')
				.with(Contact.Id, Contact.Name)
				.setLimit(10)
			).toString();

		// Verify
		Assert.areEqual('SELECT Name , (SELECT Id, Name FROM Contacts LIMIT 10) FROM Account', soql, 'The generated rflib_SOQL should match the expected one.');
	}

	@IsTest
	static void subQueryOffset() {
		// Test
		String soql = rflib_SOQL.of(Account.SObjectType)
			.with(Account.Name)
			.with(rflib_SOQL.SubQuery.of('Contacts')
				.with(Contact.Id, Contact.Name)
				.offset(100)
			).toString();

		// Verify
		Assert.areEqual('SELECT Name , (SELECT Id, Name FROM Contacts OFFSET 100) FROM Account', soql, 'The generated rflib_SOQL should match the expected one.');
	}

	@IsTest
	static void subQueryForReference() {
		// Test
		String soql = rflib_SOQL.of(Account.SObjectType)
			.with(Account.Name)
			.with(rflib_SOQL.SubQuery.of('Contacts')
				.with(Contact.Id, Contact.Name)
				.forReference()
			).toString();

		// Verify
		Assert.areEqual('SELECT Name , (SELECT Id, Name FROM Contacts FOR REFERENCE) FROM Account', soql, 'The generated rflib_SOQL should match the expected one.');
	}

	@IsTest
	static void subQueryForView() {
		// Test
		String soql = rflib_SOQL.of(Account.SObjectType)
			.with(Account.Name)
			.with(rflib_SOQL.SubQuery.of('Contacts')
				.with(Contact.Id, Contact.Name)
				.forView()
			).toString();

		// Verify
		Assert.areEqual('SELECT Name , (SELECT Id, Name FROM Contacts FOR VIEW) FROM Account', soql, 'The generated rflib_SOQL should match the expected one.');
	}

	@IsTest
	static void multipleSubQueriesWithConditions() {
		// Setup
		String leadSource = 'Web';
		Date fromDate = Date.newInstance(2024, 1, 1);
		Date toDate = Date.newInstance(2024, 1, 30);

		// Test
		rflib_SOQL.Queryable builder = rflib_SOQL.of(Account.SObjectType)
			.with(
				rflib_SOQL.SubQuery.of('Contacts')
					.with(Contact.Id)
					.whereAre(rflib_SOQL.FilterGroup
						.add(rflib_SOQL.Filter.with(Contact.CreatedDate).lessOrEqual(fromDate))
						.add(rflib_SOQL.Filter.with(Contact.CreatedDate).isNull())
						.add(rflib_SOQL.Filter.with(Contact.CreatedDate).greaterOrEqual(toDate))
						.conditionLogic('1 AND (2 OR 3)')
					)
			)
			.with(
				rflib_SOQL.SubQuery.of('Opportunities')
					.with(Opportunity.Id)
					.whereAre(rflib_SOQL.FilterGroup
						.add(rflib_SOQL.Filter.with(Opportunity.LeadSource).equal(leadSource))
						.add(rflib_SOQL.Filter.with(Contact.CreatedDate).equal(fromDate))
					)
			)
			.setLimit(1);

		// Verify
		Assert.areEqual(
			'SELECT Id , (SELECT Id FROM Contacts WHERE (CreatedDate <= :v1 AND (CreatedDate = :v2 OR CreatedDate >= :v3))), (SELECT Id FROM Opportunities WHERE (LeadSource = :v4 AND CreatedDate = :v5)) FROM Account LIMIT 1',
			builder.toString(),
			'The generated rflib_SOQL should match the expected one.'
		);

		Map<String, Object> binding = builder.binding();
		Assert.areEqual(fromDate, binding.get('v1'), 'The binding variable should match the expected value.');
		Assert.areEqual(null, binding.get('v2'), 'The binding variable should match the expected value.');
		Assert.areEqual(toDate, binding.get('v3'), 'The binding variable should match the expected value.');
		Assert.areEqual(leadSource, binding.get('v4'), 'The binding variable should match the expected value.');
		Assert.areEqual(fromDate, binding.get('v5'), 'The binding variable should match the expected value.');
	}

	@IsTest
	static void delegatedScope() {
		// Test
		String soql = rflib_SOQL.of(Task.SObjectType)
			.delegatedScope()
			.toString();

		// Verify
		Assert.areEqual('SELECT Id FROM Task USING SCOPE DELEGATED', soql, 'The generated rflib_SOQL should match the expected one.');
	}

	@IsTest
	static void mineScope() {
		// Test
		String soql = rflib_SOQL.of(Account.SObjectType)
			.mineScope()
			.toString();

		// Verify
		Assert.areEqual('SELECT Id FROM Account USING SCOPE MINE', soql, 'The generated rflib_SOQL should match the expected one.');
	}

	@IsTest
	static void mineAndMyGroupsScope() {
		// Test
		String soql = rflib_SOQL.of(ProcessInstanceWorkitem.SObjectType)
			.mineAndMyGroupsScope()
			.toString();

		// Verify
		Assert.areEqual('SELECT Id FROM ProcessInstanceWorkitem USING SCOPE MINE_AND_MY_GROUPS', soql, 'The generated rflib_SOQL should match the expected one.');
	}

	@IsTest
	static void myTerritoryScope() {
		// Test
		String soql = rflib_SOQL.of(Account.SObjectType)
			.myTerritoryScope()
			.toString();

		// Verify
		Assert.areEqual('SELECT Id FROM Account USING SCOPE MY_TERRITORY', soql, 'The generated rflib_SOQL should match the expected one.');
	}

	@IsTest
	static void myTeamTerritoryScope() {
		// Test
		String soql = rflib_SOQL.of(Account.SObjectType)
			.myTeamTerritoryScope()
			.toString();

		// Verify
		Assert.areEqual('SELECT Id FROM Account USING SCOPE MY_TEAM_TERRITORY', soql, 'The generated rflib_SOQL should match the expected one.');
	}

	@IsTest
	static void teamScope() {
		// Test
		String soql = rflib_SOQL.of(Account.SObjectType)
			.teamScope()
			.toString();

		// Verify
		Assert.areEqual('SELECT Id FROM Account USING SCOPE TEAM', soql, 'The generated rflib_SOQL should match the expected one.');
	}

	@IsTest
	static void filterId() {
		// Test
		rflib_SOQL.Queryable builder = rflib_SOQL.of(Account.SObjectType)
			.whereAre(rflib_SOQL.Filter.id().isNotNull());

		// Verify
		String soql = builder.toString();
		Assert.areEqual('SELECT Id FROM Account WHERE Id != :v1', soql, 'The generated rflib_SOQL should match the expected one.');

		Map<String, Object> binding = builder.binding();
		Assert.areEqual(null, binding.get('v1'), 'The binding variable should match the expected value.');
	}

	@IsTest
	static void filterRecordType() {
		// Test
		rflib_SOQL.Queryable builder = rflib_SOQL.of(Account.SObjectType)
			.whereAre(rflib_SOQL.Filter.recordType().isNotNull());

		// Verify
		String soql = builder.toString();
		Assert.areEqual('SELECT Id FROM Account WHERE RecordType.DeveloperName != :v1', soql, 'The generated rflib_SOQL should match the expected one.');

		Map<String, Object> binding = builder.binding();
		Assert.areEqual(null, binding.get('v1'), 'The binding variable should match the expected value.');
	}

	@IsTest
	static void filterName() {
		// Test
		rflib_SOQL.Queryable builder = rflib_SOQL.of(Account.SObjectType)
			.whereAre(rflib_SOQL.Filter.name().isNotNull());

		// Verify
		String soql = builder.toString();
		Assert.areEqual('SELECT Id FROM Account WHERE Name != :v1', soql, 'The generated rflib_SOQL should match the expected one.');

		Map<String, Object> binding = builder.binding();
		Assert.areEqual(null, binding.get('v1'), 'The binding variable should match the expected value.');
	}

	@IsTest
	static void filterWithRelatedField() {
		// Test
		rflib_SOQL.Queryable builder = rflib_SOQL.of(Contact.SObjectType)
			.whereAre(rflib_SOQL.Filter.with('Account', Account.Name).equal('Test'));

		// Verify
		String soql = builder.toString();
		Assert.areEqual('SELECT Id FROM Contact WHERE Account.Name = :v1', soql, 'The generated rflib_SOQL should match the expected one.');

		Map<String, Object> binding = builder.binding();
		Assert.areEqual('Test', binding.get('v1'), 'The binding variable should match the expected value.');
	}

	@IsTest
	static void filterEqualString() {
		// Test
		rflib_SOQL.Queryable builder = rflib_SOQL.of(Account.SObjectType)
			.whereAre(rflib_SOQL.Filter.with(Account.Name).equal('Test'));

		// Verify
		String soql = builder.toString();
		Assert.areEqual('SELECT Id FROM Account WHERE Name = :v1', soql, 'The generated rflib_SOQL should match the expected one.');

		Map<String, Object> binding = builder.binding();
		Assert.areEqual('Test', binding.get('v1'), 'The binding variable should match the expected value.');
	}

	@IsTest
	static void filterNotEqualString() {
		// Test
		rflib_SOQL.Queryable builder = rflib_SOQL.of(Account.SObjectType)
			.whereAre(rflib_SOQL.Filter.with(Account.Name).notEqual('Test'));

		// Verify
		String soql = builder.toString();
		Assert.areEqual('SELECT Id FROM Account WHERE Name != :v1', soql, 'The generated rflib_SOQL should match the expected one.');

		Map<String, Object> binding = builder.binding();
		Assert.areEqual('Test', binding.get('v1'), 'The binding variable should match the expected value.');
	}

	@IsTest
	static void filterLessThan() {
		// Test
		rflib_SOQL.Queryable builder = rflib_SOQL.of(Account.SObjectType)
			.whereAre(rflib_SOQL.Filter.with(Account.NumberOfEmployees).lessThan(10));

		// Verify
		String soql = builder.toString();
		Assert.areEqual('SELECT Id FROM Account WHERE NumberOfEmployees < :v1', soql, 'The generated rflib_SOQL should match the expected one.');

		Map<String, Object> binding = builder.binding();
		Assert.areEqual(10, binding.get('v1'), 'The binding variable should match the expected value.');
	}

	@IsTest
	static void filterGreaterThan() {
		// Test
		rflib_SOQL.Queryable builder = rflib_SOQL.of(Account.SObjectType)
			.whereAre(rflib_SOQL.Filter.with(Account.NumberOfEmployees).greaterThan(10));

		// Verify
		String soql = builder.toString();
		Assert.areEqual('SELECT Id FROM Account WHERE NumberOfEmployees > :v1', soql, 'The generated rflib_SOQL should match the expected one.');

		Map<String, Object> binding = builder.binding();
		Assert.areEqual(10, binding.get('v1'), 'The binding variable should match the expected value.');
	}

	@IsTest
	static void filterLessOrEqual() {
		// Test
		rflib_SOQL.Queryable builder = rflib_SOQL.of(Account.SObjectType)
			.whereAre(rflib_SOQL.Filter.with(Account.NumberOfEmployees).lessOrEqual(10));

		// Verify
		String soql = builder.toString();
		Assert.areEqual('SELECT Id FROM Account WHERE NumberOfEmployees <= :v1', soql, 'The generated rflib_SOQL should match the expected one.');

		Map<String, Object> binding = builder.binding();
		Assert.areEqual(10, binding.get('v1'), 'The binding variable should match the expected value.');
	}

	@IsTest
	static void filterGreaterOrEqual() {
		// Test
		rflib_SOQL.Queryable builder = rflib_SOQL.of(Account.SObjectType)
			.whereAre(rflib_SOQL.Filter.with(Account.NumberOfEmployees).greaterOrEqual(10));

		// Verify
		String soql = builder.toString();
		Assert.areEqual('SELECT Id FROM Account WHERE NumberOfEmployees >= :v1', soql, 'The generated rflib_SOQL should match the expected one.');

		Map<String, Object> binding = builder.binding();
		Assert.areEqual(10, binding.get('v1'), 'The binding variable should match the expected value.');
	}

	@IsTest
	static void filterContains() {
		// Test
		rflib_SOQL.Queryable builder = rflib_SOQL.of(Account.SObjectType)
			.whereAre(rflib_SOQL.Filter.with(Account.Name).contains('Test'));

		// Verify
		String soql = builder.toString();
		Assert.areEqual('SELECT Id FROM Account WHERE Name LIKE :v1', soql, 'The generated rflib_SOQL should match the expected one.');

		Map<String, Object> binding = builder.binding();
		Assert.areEqual('%Test%', binding.get('v1'), 'The binding variable should match the expected value.');
	}

	@IsTest
	static void filterContainsNull() {
		// Test
		rflib_SOQL.Queryable builder = rflib_SOQL.of(Account.SObjectType)
			.whereAre(rflib_SOQL.Filter.with(Account.Name).contains(null));

		// Verify
		String soql = builder.toString();
		Assert.areEqual('SELECT Id FROM Account WHERE Name LIKE :v1', soql, 'The generated rflib_SOQL should match the expected one.');

		Map<String, Object> binding = builder.binding();
		Assert.areEqual('%null%', binding.get('v1'), 'The binding variable should match the expected value.');
	}

	@IsTest
	static void filterNotContains() {
		// Test
		rflib_SOQL.Queryable builder = rflib_SOQL.of(Account.SObjectType)
			.whereAre(rflib_SOQL.Filter.with(Account.Name).notContains('Test'));

		// Verify
		String soql = builder.toString();
		Assert.areEqual('SELECT Id FROM Account WHERE (NOT Name LIKE :v1)', soql, 'The generated rflib_SOQL should match the expected one.');

		Map<String, Object> binding = builder.binding();
		Assert.areEqual('%Test%', binding.get('v1'), 'The binding variable should match the expected value.');
	}

	@IsTest
	static void filterContainsValues() {
		// Setup
		List<String> names = new List<String>{ 'Acc', 'My' };

		// Test
		rflib_SOQL.Queryable builder = rflib_SOQL.of(Account.SObjectType)
			.whereAre(rflib_SOQL.Filter.with(Account.Name).containsSome(names));

		// Verify
		String soql = builder.toString();
		Assert.areEqual('SELECT Id FROM Account WHERE Name LIKE :v1', soql, 'The generated rflib_SOQL should match the expected one.');

		Map<String, Object> binding = builder.binding();
		Assert.areEqual(names, binding.get('v1'), 'The binding variable should match the expected value.');
	}

	@IsTest
	static void filterEndsWith() {
		// Test
		rflib_SOQL.Queryable builder = rflib_SOQL.of(Account.SObjectType)
			.whereAre(rflib_SOQL.Filter.with(Account.Name).endsWith('Test'));

		// Verify
		String soql = builder.toString();
		Assert.areEqual('SELECT Id FROM Account WHERE Name LIKE :v1', soql, 'The generated rflib_SOQL should match the expected one.');

		Map<String, Object> binding = builder.binding();
		Assert.areEqual('%Test', binding.get('v1'), 'The binding variable should match the expected value.');
	}

	@IsTest
	static void filterNotEndsWith() {
		// Test
		rflib_SOQL.Queryable builder = rflib_SOQL.of(Account.SObjectType)
			.whereAre(rflib_SOQL.Filter.with(Account.Name).notEndsWith('Test'));

		// Verify
		String soql = builder.toString();
		Assert.areEqual('SELECT Id FROM Account WHERE (NOT Name LIKE :v1)', soql, 'The generated rflib_SOQL should match the expected one.');

		Map<String, Object> binding = builder.binding();
		Assert.areEqual('%Test', binding.get('v1'), 'The binding variable should match the expected value.');
	}

	@IsTest
	static void filterStartsWith() {
		// Test
		rflib_SOQL.Queryable builder = rflib_SOQL.of(Account.SObjectType)
			.whereAre(rflib_SOQL.Filter.with(Account.Name).startsWith('Test'));

		// Verify
		String soql = builder.toString();
		Assert.areEqual('SELECT Id FROM Account WHERE Name LIKE :v1', soql, 'The generated rflib_SOQL should match the expected one.');

		Map<String, Object> binding = builder.binding();
		Assert.areEqual('Test%', binding.get('v1'), 'The binding variable should match the expected value.');
	}

	@IsTest
	static void filterNotStartsWith() {
		// Test
		rflib_SOQL.Queryable builder = rflib_SOQL.of(Account.SObjectType)
			.whereAre(rflib_SOQL.Filter.with(Account.Name).notStartsWith('Test'));

		// Verify
		String soql = builder.toString();
		Assert.areEqual('SELECT Id FROM Account WHERE (NOT Name LIKE :v1)', soql, 'The generated rflib_SOQL should match the expected one.');

		Map<String, Object> binding = builder.binding();
		Assert.areEqual('Test%', binding.get('v1'), 'The binding variable should match the expected value.');
	}

	@IsTest
	static void filterCustomContains() {
		// Test
		rflib_SOQL.Queryable builder = rflib_SOQL.of(Account.SObjectType)
			.whereAre(rflib_SOQL.Filter.with(Account.Name).contains('_', 'Test', '%'));

		// Verify
		String soql = builder.toString();
		Assert.areEqual('SELECT Id FROM Account WHERE Name LIKE :v1', soql, 'The generated rflib_SOQL should match the expected one.');

		Map<String, Object> binding = builder.binding();
		Assert.areEqual('_Test%', binding.get('v1'), 'The binding variable should match the expected value.');
	}

	@IsTest
	static void filterCustomNotContains() {
		// Test
		rflib_SOQL.Queryable builder = rflib_SOQL.of(Account.SObjectType)
			.whereAre(rflib_SOQL.Filter.with(Account.Name).notContains('_', 'Test', '%'));

		// Verify
		String soql = builder.toString();
		Assert.areEqual('SELECT Id FROM Account WHERE (NOT Name LIKE :v1)', soql, 'The generated rflib_SOQL should match the expected one.');

		Map<String, Object> binding = builder.binding();
		Assert.areEqual('_Test%', binding.get('v1'), 'The binding variable should match the expected value.');
	}

	@IsTest
	static void filterIsInSet() {
		// Setup
		Set<String> names = new Set<String>{ 'Test 1', 'Test 2' };

		// Test
		rflib_SOQL.Queryable builder = rflib_SOQL.of(Account.SObjectType)
			.whereAre(rflib_SOQL.Filter.with(Account.Name).isIn(names));

		// Verify
		String soql = builder.toString();
		Assert.areEqual('SELECT Id FROM Account WHERE Name IN :v1', soql, 'The generated rflib_SOQL should match the expected one.');

		Map<String, Object> binding = builder.binding();
		Assert.areEqual(names, binding.get('v1'), 'The binding variable should match the expected value.');
	}

	@IsTest
	static void filterIsInList() {
		// Setup
		List<String> names = new List<String>{ 'Test 1', 'Test 2' };

		// Test
		rflib_SOQL.Queryable builder = rflib_SOQL.of(Account.SObjectType)
			.whereAre(rflib_SOQL.Filter.with(Account.Name).isIn(names));

		// Verify
		String soql = builder.toString();
		Assert.areEqual('SELECT Id FROM Account WHERE Name IN :v1', soql, 'The generated rflib_SOQL should match the expected one.');

		Map<String, Object> binding = builder.binding();
		Assert.areEqual(names, binding.get('v1'), 'The binding variable should match the expected value.');
	}

	@IsTest
	static void filterNotInSet() {
		// Setup
		Set<String> names = new Set<String>{ 'Test 1', 'Test 2' };

		// Test
		rflib_SOQL.Queryable builder = rflib_SOQL.of(Account.SObjectType)
			.whereAre(rflib_SOQL.Filter.with(Account.Name).notIn(names));

		// Verify
		String soql = builder.toString();
		Assert.areEqual('SELECT Id FROM Account WHERE Name NOT IN :v1', soql, 'The generated rflib_SOQL should match the expected one.');

		Map<String, Object> binding = builder.binding();
		Assert.areEqual(names, binding.get('v1'), 'The binding variable should match the expected value.');
	}

	@IsTest
	static void filterNotInList() {
		// Setup
		List<String> names = new List<String>{ 'Test 1', 'Test 2' };

		// Test
		rflib_SOQL.Queryable builder = rflib_SOQL.of(Account.SObjectType)
			.with(Account.Name, Account.BillingCity)
			.whereAre(rflib_SOQL.Filter.with(Account.Name).notIn(names));

		// Verify
		String soql = builder.toString();
		Assert.areEqual('SELECT Name, BillingCity FROM Account WHERE Name NOT IN :v1', soql, 'The generated rflib_SOQL should match the expected one.');

		Map<String, Object> binding = builder.binding();
		Assert.areEqual(names, binding.get('v1'), 'The binding variable should match the expected value.');
	}

	@IsTest
	static void filterIncludesAll() {
		// Setup
		List<String> ratings = new List<String>{ 'Hot', 'Warm' };

		// Test
		String soql = rflib_SOQL.of(Account.SObjectType)
			.with(Account.Id)
			.whereAre(rflib_SOQL.Filter.with(Account.Rating).includesAll(ratings))
			.toString();

		// Verify
		Assert.areEqual('SELECT Id FROM Account WHERE Rating INCLUDES (\'Hot;Warm\')', soql, 'The generated rflib_SOQL should match the expected one.');
	}

	@IsTest
	static void filterIncludesSome() {
		// Setup
		List<String> ratings = new List<String>{ 'Hot', 'Warm' };

		// Test
		String soql = rflib_SOQL.of(Account.SObjectType)
			.with(Account.Id)
			.whereAre(rflib_SOQL.Filter.with(Account.Rating).includesSome(ratings))
			.toString();

		// Verify
		Assert.areEqual('SELECT Id FROM Account WHERE Rating INCLUDES (\'Hot\', \'Warm\')', soql, 'The generated rflib_SOQL should match the expected one.');
	}

	@IsTest
	static void filterExcludesAll() {
		// Setup
		List<String> ratings = new List<String>{ 'Hot', 'Warm' };

		// Test
		String soql = rflib_SOQL.of(Account.SObjectType)
			.with(Account.Id)
			.whereAre(rflib_SOQL.Filter.with(Account.Rating).excludesAll(ratings))
			.toString();

		// Verify
		Assert.areEqual('SELECT Id FROM Account WHERE Rating EXCLUDES (\'Hot\', \'Warm\')', soql, 'The generated rflib_SOQL should match the expected one.');
	}

	@IsTest
	static void filterExcludesSome() {
		// Setup
		List<String> ratings = new List<String>{ 'Hot', 'Warm' };

		// Test
		String soql = rflib_SOQL.of(Account.SObjectType)
			.with(Account.Id)
			.whereAre(rflib_SOQL.Filter.with(Account.Rating).excludesSome(ratings))
			.toString();

		// Verify
		Assert.areEqual('SELECT Id FROM Account WHERE Rating EXCLUDES (\'Hot;Warm\')', soql, 'The generated rflib_SOQL should match the expected one.');
	}

	@IsTest
	static void filterIsNull() {
		// Test
		rflib_SOQL.Queryable builder = rflib_SOQL.of(Account.SObjectType)
			.whereAre(rflib_SOQL.Filter.with(Account.Name).isNull());

		// Verify
		String soql = builder.toString();
		Assert.areEqual('SELECT Id FROM Account WHERE Name = :v1', soql, 'The generated rflib_SOQL should match the expected one.');

		Map<String, Object> binding = builder.binding();
		Assert.areEqual(null, binding.get('v1'), 'The binding variable should match the expected value.');
	}

	@IsTest
	static void filterIsNotNull() {
		// Test
		rflib_SOQL.Queryable builder = rflib_SOQL.of(Account.SObjectType)
			.whereAre(rflib_SOQL.Filter.with(Account.Name).isNotNull());

		// Verify
		String soql = builder.toString();
		Assert.areEqual('SELECT Id FROM Account WHERE Name != :v1', soql, 'The generated rflib_SOQL should match the expected one.');

		Map<String, Object> binding = builder.binding();
		Assert.areEqual(null, binding.get('v1'), 'The binding variable should match the expected value.');
	}

	@IsTest
	static void filterIsTrue() {
		// Test
		rflib_SOQL.Queryable builder = rflib_SOQL.of(Account.SObjectType)
			.whereAre(rflib_SOQL.Filter.with(Account.IsDeleted).isTrue());

		// Verify
		String soql = builder.toString();
		Assert.areEqual('SELECT Id FROM Account WHERE IsDeleted = :v1', soql, 'The generated rflib_SOQL should match the expected one.');

		Map<String, Object> binding = builder.binding();
		Assert.isTrue((Boolean) binding.get('v1'), 'The binding variable should match the expected value.');
	}

	@IsTest
	static void filterIsFalse() {
		// Test
		rflib_SOQL.Queryable builder = rflib_SOQL.of(Account.SObjectType)
			.whereAre(rflib_SOQL.Filter.with(Account.IsDeleted).isFalse());

		// Verify
		String soql = builder.toString();
		Assert.areEqual('SELECT Id FROM Account WHERE IsDeleted = :v1', soql, 'The generated rflib_SOQL should match the expected one.');

		Map<String, Object> binding = builder.binding();
		Assert.isFalse((Boolean) binding.get('v1'), 'The binding variable should match the expected value.');
	}

	@IsTest
	static void filterDateLiteral() {
		// Test
		String soql = rflib_SOQL.of(Account.SObjectType)
			.whereAre(rflib_SOQL.Filter.with(Account.CreatedDate).greaterThan('LAST_N_QUARTERS:2').asDateLiteral())
			.toString();

		// Verify
		Assert.areEqual('SELECT Id FROM Account WHERE CreatedDate > LAST_N_QUARTERS:2', soql, 'The generated rflib_SOQL should match the expected one.');
	}

	@IsTest
	static void filtersGroup() {
		// Test
		rflib_SOQL.Queryable builder = rflib_SOQL.of(Account.SObjectType)
			.whereAre(rflib_SOQL.FilterGroup
				.add(rflib_SOQL.Filter.with(Account.Name).equal('Test'))
				.add(rflib_SOQL.Filter.with(Account.BillingCity).equal('Krakow'))
			);

		// Verify
		Assert.areEqual('SELECT Id FROM Account WHERE (Name = :v1 AND BillingCity = :v2)', builder.toString(), 'The generated rflib_SOQL should match the expected one.');

		Map<String, Object> binding = builder.binding();
		Assert.areEqual('Test', binding.get('v1'), 'The binding variable should match the expected value.');
		Assert.areEqual('Krakow', binding.get('v2'), 'The binding variable should match the expected value.');
	}

	@IsTest
	static void emptyFiltersGroup() {
		// Test
		String soql = rflib_SOQL.of(Account.SObjectType)
			.whereAre(rflib_SOQL.FilterGroup)
			.toString();

		// Verify
		Assert.areEqual('SELECT Id FROM Account', soql, 'The generated rflib_SOQL should match the expected one.');
	}

	@IsTest
	static void dynamicFiltersGroup() {
		// Setup
		rflib_SOQL.FilterGroup filterGroup = rflib_SOQL.FilterGroup;

		filterGroup.add(rflib_SOQL.Filter.with(Account.Name).equal('Test'));
		filterGroup.add(rflib_SOQL.Filter.with(Account.BillingCity).equal('Krakow'));

		// Test
		rflib_SOQL.Queryable builder = rflib_SOQL.of(Account.SObjectType)
			.whereAre(filterGroup);

		// Verify
		String soql = builder.toString();
		Assert.areEqual('SELECT Id FROM Account WHERE (Name = :v1 AND BillingCity = :v2)', soql, 'The generated rflib_SOQL should match the expected one.');

		Map<String, Object> binding = builder.binding();
		Assert.areEqual('Test', binding.get('v1'), 'The binding variable should match the expected value.');
		Assert.areEqual('Krakow', binding.get('v2'), 'The binding variable should match the expected value.');
	}

	@IsTest
	static void dynamicFiltersListGroup() {
		// Setup
		rflib_SOQL.FilterGroup filterGroup = rflib_SOQL.FilterGroup;

		filterGroup.add(new List<rflib_SOQL.Filter> {
			rflib_SOQL.Filter.with(Account.Name).equal('Test'),
			rflib_SOQL.Filter.with(Account.BillingCity).equal('Krakow')
		});

		// Test
		rflib_SOQL.Queryable builder = rflib_SOQL.of(Account.SObjectType)
			.whereAre(filterGroup);

		// Verify
		String soql = builder.toString();
		Assert.areEqual('SELECT Id FROM Account WHERE (Name = :v1 AND BillingCity = :v2)', soql, 'The generated rflib_SOQL should match the expected one.');

		Map<String, Object> binding = builder.binding();
		Assert.areEqual('Test', binding.get('v1'), 'The binding variable should match the expected value.');
		Assert.areEqual('Krakow', binding.get('v2'), 'The binding variable should match the expected value.');
	}

	@IsTest
	static void dynamicStringFiltersGroup() {
		// Setup
		rflib_SOQL.FilterGroup filterGroup = rflib_SOQL.FilterGroup;

		filterGroup.add('Name = \'Test\'');
		filterGroup.add('BillingCity = \'Krakow\'');

		// Test
		String soql = rflib_SOQL.of(Account.SObjectType)
			.whereAre(filterGroup)
			.toString();

		// Verify
		Assert.areEqual('SELECT Id FROM Account WHERE (Name = \'Test\' AND BillingCity = \'Krakow\')', soql, 'The generated rflib_SOQL should match the expected one.');
	}

	@IsTest
	static void dynamicStringFiltersGroupWithAnyConditionMatching() {
		// Setup
		rflib_SOQL.FilterGroup filterGroup = rflib_SOQL.FilterGroup;

		filterGroup.add('Name = \'Test\'');
		filterGroup.add('BillingCity = \'Krakow\'');
		filterGroup.anyConditionMatching();

		// Test
		String soql = rflib_SOQL.of(Account.SObjectType)
			.whereAre(filterGroup)
			.toString();

		// Verify
		Assert.areEqual('SELECT Id FROM Account WHERE (Name = \'Test\' OR BillingCity = \'Krakow\')', soql, 'The generated rflib_SOQL should match the expected one.');
	}

	@IsTest
	static void dynamicStringFiltersListGroup() {
		// Test
		String soql = rflib_SOQL.of(Account.SObjectType)
			.whereAre(rflib_SOQL.FilterGroup
				.add(new List<String> {
					'Name = \'Test\'',
					'BillingCity = \'Krakow\''
				})
			).toString();

		// Verify
		Assert.areEqual('SELECT Id FROM Account WHERE (Name = \'Test\' AND BillingCity = \'Krakow\')', soql, 'The generated rflib_SOQL should match the expected one.');
	}

	@IsTest
	static void dynamicStringFiltersListGroupWithAnyConditionMatching() {
		// Setup
		rflib_SOQL.FilterGroup filterGroup = rflib_SOQL.FilterGroup;

		filterGroup.add(new List<String> {
			'Name = \'Test\'',
			'BillingCity = \'Krakow\''
		});

		// Test
		String soql = rflib_SOQL.of(Account.SObjectType)
			.whereAre(rflib_SOQL.FilterGroup
				.add(new List<String> {
					'Name = \'Test\'',
					'BillingCity = \'Krakow\''
				}).anyConditionMatching()
			).toString();

		// Verify
		Assert.areEqual('SELECT Id FROM Account WHERE (Name = \'Test\' OR BillingCity = \'Krakow\')', soql, 'The generated rflib_SOQL should match the expected one.');
	}

	@IsTest
	static void dynamicFiltersGroupOnSoqlInstance() {
		// Test
		rflib_SOQL.Queryable builder = rflib_SOQL.of(Account.SObjectType)
			.whereAre(rflib_SOQL.Filter.with(Account.Industry).equal('IT'));

		Assert.areEqual('SELECT Id FROM Account WHERE Industry = :v1', builder.toString(), 'The generated rflib_SOQL should match the expected one.');

		builder.whereAre(
			rflib_SOQL.FilterGroup
				.add(rflib_SOQL.Filter.with(Account.Name).equal('Test'))
				.add(rflib_SOQL.Filter.with(Account.BillingCity).equal('Krakow'))
		);

		// Verify
		Assert.areEqual('SELECT Id FROM Account WHERE Industry = :v1 AND (Name = :v2 AND BillingCity = :v3)', builder.toString(), 'The generated rflib_SOQL should match the expected one.');

		Map<String, Object> binding = builder.binding();
		Assert.areEqual('IT', binding.get('v1'), 'The binding variable should match the expected value.');
		Assert.areEqual('Test', binding.get('v2'), 'The binding variable should match the expected value.');
		Assert.areEqual('Krakow', binding.get('v3'), 'The binding variable should match the expected value.');
	}

	@IsTest
	static void multipleFilterGroups() {
		// Test
		rflib_SOQL.Queryable builder = rflib_SOQL.of(Account.SObjectType)
			.whereAre(rflib_SOQL.FilterGroup.add(rflib_SOQL.Filter.with(Account.Name).contains('1')))
			.whereAre(rflib_SOQL.FilterGroup.add(rflib_SOQL.Filter.with(Account.Name).contains('2')))
			.whereAre(rflib_SOQL.FilterGroup.add(rflib_SOQL.Filter.with(Account.Name).contains('3')))
			.whereAre(rflib_SOQL.FilterGroup.add(rflib_SOQL.Filter.with(Account.Name).contains('4')))
			.whereAre(rflib_SOQL.FilterGroup.add(rflib_SOQL.Filter.with(Account.Name).contains('5')))
			.whereAre(rflib_SOQL.FilterGroup.add(rflib_SOQL.Filter.with(Account.Name).contains('6')))
			.whereAre(rflib_SOQL.FilterGroup.add(rflib_SOQL.Filter.with(Account.Name).contains('7')))
			.whereAre(rflib_SOQL.FilterGroup.add(rflib_SOQL.Filter.with(Account.Name).contains('8')))
			.whereAre(rflib_SOQL.FilterGroup.add(rflib_SOQL.Filter.with(Account.Name).contains('9')))
			.whereAre(rflib_SOQL.FilterGroup.add(rflib_SOQL.Filter.with(Account.Name).contains('10')))
			.whereAre(rflib_SOQL.FilterGroup.add(rflib_SOQL.Filter.with(Account.Name).contains('11')));

		// Verify
		String soql = builder.toString();
		Assert.areEqual(
			'SELECT Id FROM Account WHERE (Name LIKE :v1) AND (Name LIKE :v2) AND (Name LIKE :v3) AND (Name LIKE :v4) AND (Name LIKE :v5) AND (Name LIKE :v6) AND (Name LIKE :v7) AND (Name LIKE :v8) AND (Name LIKE :v9) AND (Name LIKE :v10) AND (Name LIKE :v11)',
			soql,
			'The generated rflib_SOQL should match the expected one.'
		);

		Map<String, Object> binding = builder.binding();
		Assert.areEqual('%1%', binding.get('v1'), 'The binding variable should match the expected value.');
		Assert.areEqual('%2%', binding.get('v2'), 'The binding variable should match the expected value.');
		Assert.areEqual('%3%', binding.get('v3'), 'The binding variable should match the expected value.');
		Assert.areEqual('%4%', binding.get('v4'), 'The binding variable should match the expected value.');
		Assert.areEqual('%5%', binding.get('v5'), 'The binding variable should match the expected value.');
		Assert.areEqual('%6%', binding.get('v6'), 'The binding variable should match the expected value.');
		Assert.areEqual('%7%', binding.get('v7'), 'The binding variable should match the expected value.');
		Assert.areEqual('%8%', binding.get('v8'), 'The binding variable should match the expected value.');
		Assert.areEqual('%9%', binding.get('v9'), 'The binding variable should match the expected value.');
		Assert.areEqual('%10%', binding.get('v10'), 'The binding variable should match the expected value.');
		Assert.areEqual('%11%', binding.get('v11'), 'The binding variable should match the expected value.');
	}

	@IsTest
	static void duplicatedConditionsInConditionOrder() {
		// Test
		rflib_SOQL.Queryable builder = rflib_SOQL.of(Account.SObjectType)
			.whereAre(rflib_SOQL.FilterGroup.add(rflib_SOQL.Filter.with(Account.Name).contains('1')))
			.whereAre(rflib_SOQL.FilterGroup.add(rflib_SOQL.Filter.with(Account.Name).contains('2')))
			.whereAre(rflib_SOQL.FilterGroup.add(rflib_SOQL.Filter.with(Account.Name).contains('3')))
			.whereAre(rflib_SOQL.FilterGroup.add(rflib_SOQL.Filter.with(Account.Name).contains('4')))
			.whereAre(rflib_SOQL.FilterGroup.add(rflib_SOQL.Filter.with(Account.Name).contains('5')))
			.whereAre(rflib_SOQL.FilterGroup.add(rflib_SOQL.Filter.with(Account.Name).contains('6')))
			.whereAre(rflib_SOQL.FilterGroup.add(rflib_SOQL.Filter.with(Account.Name).contains('7')))
			.whereAre(rflib_SOQL.FilterGroup.add(rflib_SOQL.Filter.with(Account.Name).contains('8')))
			.whereAre(rflib_SOQL.FilterGroup.add(rflib_SOQL.Filter.with(Account.Name).contains('9')))
			.whereAre(rflib_SOQL.FilterGroup.add(rflib_SOQL.Filter.with(Account.Name).contains('10')))
			.whereAre(rflib_SOQL.FilterGroup.add(rflib_SOQL.Filter.with(Account.Name).contains('11')))
			.conditionLogic('(1 AND 2 AND 3 AND 4 AND 5 AND 5 AND 7 AND 8 AND 9 AND 10 AND 11) OR (11 AND 1 AND 10)');

		// Verify
		String soql = builder.toString();
		Assert.areEqual(
			'SELECT Id FROM Account WHERE ((Name LIKE :v1) AND (Name LIKE :v2) AND (Name LIKE :v3) AND (Name LIKE :v4) AND (Name LIKE :v5) AND (Name LIKE :v5) AND (Name LIKE :v7) AND (Name LIKE :v8) AND (Name LIKE :v9) AND (Name LIKE :v10) AND (Name LIKE :v11)) OR ((Name LIKE :v11) AND (Name LIKE :v1) AND (Name LIKE :v10))',
			soql,
			'The generated rflib_SOQL should match the expected one.'
		);

		Map<String, Object> binding = builder.binding();
		Assert.areEqual('%1%', binding.get('v1'), 'The binding variable should match the expected value.');
		Assert.areEqual('%2%', binding.get('v2'), 'The binding variable should match the expected value.');
		Assert.areEqual('%3%', binding.get('v3'), 'The binding variable should match the expected value.');
		Assert.areEqual('%4%', binding.get('v4'), 'The binding variable should match the expected value.');
		Assert.areEqual('%5%', binding.get('v5'), 'The binding variable should match the expected value.');
		Assert.areEqual('%6%', binding.get('v6'), 'The binding variable should match the expected value.');
		Assert.areEqual('%7%', binding.get('v7'), 'The binding variable should match the expected value.');
		Assert.areEqual('%8%', binding.get('v8'), 'The binding variable should match the expected value.');
		Assert.areEqual('%9%', binding.get('v9'), 'The binding variable should match the expected value.');
		Assert.areEqual('%10%', binding.get('v10'), 'The binding variable should match the expected value.');
		Assert.areEqual('%11%', binding.get('v11'), 'The binding variable should match the expected value.');
	}

	@IsTest
	static void anyConditionMatchingForInnerGroup() {
		// Test
		rflib_SOQL.Queryable builder = rflib_SOQL.of(Account.SObjectType)
			.whereAre(rflib_SOQL.FilterGroup
				.add(rflib_SOQL.Filter.with(Account.Name).equal('Test'))
				.add(rflib_SOQL.Filter.with(Account.BillingCity).equal('Krakow'))
				.anyConditionMatching()
			);

		// Verify
		String soql = builder.toString();
		Assert.areEqual('SELECT Id FROM Account WHERE (Name = :v1 OR BillingCity = :v2)', soql, 'The generated rflib_SOQL should match the expected one.');

		Map<String, Object> binding = builder.binding();
		Assert.areEqual('Test', binding.get('v1'), 'The binding variable should match the expected value.');
		Assert.areEqual('Krakow', binding.get('v2'), 'The binding variable should match the expected value.');
	}

	@IsTest
	static void anyConditionMatchingForMainGroup() {
		// Test
		rflib_SOQL.Queryable builder = rflib_SOQL.of(Account.SObjectType)
			.whereAre(rflib_SOQL.Filter.with(Account.Name).equal('Test'))
			.whereAre(rflib_SOQL.Filter.with(Account.BillingCity).equal('Krakow'))
			.anyConditionMatching();

		// Verify
		String soql = builder.toString();
		Assert.areEqual('SELECT Id FROM Account WHERE Name = :v1 OR BillingCity = :v2', soql, 'The generated rflib_SOQL should match the expected one.');

		Map<String, Object> binding = builder.binding();
		Assert.areEqual('Test', binding.get('v1'), 'The binding variable should match the expected value.');
		Assert.areEqual('Krakow', binding.get('v2'), 'The binding variable should match the expected value.');
	}

	@IsTest
	static void conditionLogicForMainGroup() {
		// Test
		rflib_SOQL.Queryable builder = rflib_SOQL.of(Account.SObjectType)
			.whereAre(rflib_SOQL.Filter.with(Account.Name).equal('Test'))
			.whereAre(rflib_SOQL.Filter.with(Account.BillingCity).equal('Krakow'))
			.conditionLogic('1 OR 2');

		// Verify
		String soql = builder.toString();
		Assert.areEqual('SELECT Id FROM Account WHERE Name = :v1 OR BillingCity = :v2', soql, 'The generated rflib_SOQL should match the expected one.');

		Map<String, Object> binding = builder.binding();
		Assert.areEqual('Test', binding.get('v1'), 'The binding variable should match the expected value.');
		Assert.areEqual('Krakow', binding.get('v2'), 'The binding variable should match the expected value.');
	}

	@IsTest
	static void nestedFiltersGroup() {
		// Test
		rflib_SOQL.Queryable builder = rflib_SOQL.of(Account.SObjectType)
			.whereAre(rflib_SOQL.FilterGroup
				.add(rflib_SOQL.Filter.with(Account.Name).equal('Test'))
				.add(rflib_SOQL.Filter.with(Account.BillingCity).equal('Krakow'))
				.add(rflib_SOQL.FilterGroup
					.add(rflib_SOQL.Filter.with(Account.Name).equal('Test 2'))
					.add(rflib_SOQL.Filter.with(Account.BillingCity).equal('Warsaw'))
					.conditionLogic('1 OR 2')
				)
			);

		// Verify
		String soql = builder.toString();
		Assert.areEqual('SELECT Id FROM Account WHERE (Name = :v1 AND BillingCity = :v2 AND (Name = :v3 OR BillingCity = :v4))', soql, 'The generated rflib_SOQL should match the expected one.');

		Map<String, Object> binding = builder.binding();
		Assert.areEqual('Test', binding.get('v1'), 'The binding variable should match the expected value.');
		Assert.areEqual('Krakow', binding.get('v2'), 'The binding variable should match the expected value.');
		Assert.areEqual('Test 2', binding.get('v3'), 'The binding variable should match the expected value.');
		Assert.areEqual('Warsaw', binding.get('v4'), 'The binding variable should match the expected value.');
	}

	@IsTest
	static void innerJoinWithFilterGroup() {
		// Test
		rflib_SOQL.Queryable builder = rflib_SOQL.of(Account.SObjectType)
			.whereAre(rflib_SOQL.Filter.with(Account.Id).isIn(
				rflib_SOQL.InnerJoin.of(Contact.SObjectType)
					.with(Contact.AccountId)
					.whereAre(rflib_SOQL.FilterGroup
						.add(rflib_SOQL.Filter.with(Contact.Name).equal('My Contact'))
					)
			));

		// Verify
		String soql = builder.toString();
		Assert.areEqual('SELECT Id FROM Account WHERE Id IN (SELECT AccountId FROM Contact WHERE (Name = :v1))', soql, 'The generated rflib_SOQL should match the expected one.');

		Map<String, Object> binding = builder.binding();
		Assert.areEqual('My Contact', binding.get('v1'), 'The binding variable should match the expected value.');
	}

	@IsTest
	static void inInnerJoin() {
		// Test
		rflib_SOQL.Queryable builder = rflib_SOQL.of(Account.SObjectType)
			.whereAre(rflib_SOQL.Filter.with(Account.Id).isIn(
				rflib_SOQL.InnerJoin.of(Contact.SObjectType)
					.with(Contact.AccountId)
					.whereAre(rflib_SOQL.Filter.with(Contact.Name).equal('My Contact'))
			));

		// Verify
		String soql = builder.toString();
		Assert.areEqual('SELECT Id FROM Account WHERE Id IN (SELECT AccountId FROM Contact WHERE Name = :v1)', soql, 'The generated rflib_SOQL should match the expected one.');

		Map<String, Object> binding = builder.binding();
		Assert.areEqual('My Contact', binding.get('v1'), 'The binding variable should match the expected value.');
	}

	@IsTest
	static void isNotInInnerJoin() {
		// Test
		rflib_SOQL.Queryable builder = rflib_SOQL.of(Account.SObjectType)
			.whereAre(rflib_SOQL.Filter.with(Account.Id).notIn(
				rflib_SOQL.InnerJoin.of(Contact.SObjectType)
					.with(Contact.AccountId)
					.whereAre(rflib_SOQL.Filter.name().equal('My Contact'))
			));

		// Verify
		String soql = builder.toString();
		Assert.areEqual('SELECT Id FROM Account WHERE Id NOT IN (SELECT AccountId FROM Contact WHERE Name = :v1)', soql, 'The generated rflib_SOQL should match the expected one.');

		Map<String, Object> binding = builder.binding();
		Assert.areEqual('My Contact', binding.get('v1'), 'The binding variable should match the expected value.');
	}

	@IsTest
	static void evaluateStringConditions() {
		// Test
		String soql = rflib_SOQL.of(Account.SObjectType)
			.whereAre('NumberOfEmployees >= 10 AND NumberOfEmployees <= 20')
			.toString();

		// Verify
		Assert.areEqual('SELECT Id FROM Account WHERE NumberOfEmployees >= 10 AND NumberOfEmployees <= 20', soql, 'The generated rflib_SOQL should match the expected one.');
	}

	@IsTest
	static void evaluateEmptyConditions() {
		// Test
		String soql = rflib_SOQL.of(Account.SObjectType)
			.whereAre('')
			.toString();

		// Verify
		Assert.areEqual('SELECT Id FROM Account', soql, 'The generated rflib_SOQL should match the expected one.');
	}

	@IsTest
	static void evaluateStringConditionsAndGroup() {
		// Test
		String soql = rflib_SOQL.of(Account.SObjectType)
			.whereAre('NumberOfEmployees >= 10 AND NumberOfEmployees <= 20')
			.whereAre(rflib_SOQL.Filter.name().equal('My Contact'))
			.toString();

		// Verify
		Assert.areEqual('SELECT Id FROM Account WHERE NumberOfEmployees >= 10 AND NumberOfEmployees <= 20 AND Name = :v1', soql, 'The generated rflib_SOQL should match the expected one.');
	}

	@IsTest
	static void evaluateStringAndFilterInFilterGroup() {
		// Test
		String soql = rflib_SOQL.of(Account.SObjectType)
			.whereAre(
				rflib_SOQL.FilterGroup
					.add('NumberOfEmployees >= 10 AND NumberOfEmployees <= 20')
					.add(rflib_SOQL.Filter.name().equal('My Contact'))
			)
			.toString();

		// Verify
		Assert.areEqual('SELECT Id FROM Account WHERE (NumberOfEmployees >= 10 AND NumberOfEmployees <= 20 AND Name = :v1)', soql, 'The generated rflib_SOQL should match the expected one.');
	}

	@IsTest
	static void filterIgnoreWhen() {
		// Setup
		String accountName = '';

		// Test
		String soql = rflib_SOQL.of(Account.SObjectType)
			.whereAre(rflib_SOQL.FilterGroup
				.add(rflib_SOQL.Filter.with(Account.BillingCity).equal('Krakow'))
				.add(rflib_SOQL.Filter.name().contains(accountName).ignoreWhen(String.isEmpty(accountName)))
			)
			.toString();

		// Verify
		Assert.areEqual('SELECT Id FROM Account WHERE (BillingCity = :v1)', soql, 'The generated rflib_SOQL should match the expected one.');
	}

	@IsTest
	static void filterGroupIgnoreWhen() {
		// Setup
		Boolean isPartnerUser = false;

		// Test
		String soql = rflib_SOQL.of(Account.SObjectType)
			.whereAre(rflib_SOQL.FilterGroup
				.add(rflib_SOQL.FilterGroup
					.add(rflib_SOQL.Filter.with(Account.BillingCity).equal('Krakow'))
						.add(rflib_SOQL.Filter.with(Account.BillingCity).equal('Warsaw'))
						.anyConditionMatching()
						.ignoreWhen(!isPartnerUser)
				)
				.add(rflib_SOQL.FilterGroup
					.add(rflib_SOQL.Filter.with(Account.Industry).equal('IT'))
					.add(rflib_SOQL.Filter.name().contains('MyAccount'))
				)
			)
			.toString();

		// Verify
		Assert.areEqual('SELECT Id FROM Account WHERE ((Industry = :v1 AND Name LIKE :v2))', soql, 'The generated rflib_SOQL should match the expected one.');
	}

	@IsTest
	static void groupBy() {
		// Test
		String soql = rflib_SOQL.of(Lead.SObjectType)
			.with(Lead.LeadSource)
			.groupBy(Lead.LeadSource)
			.toString();

		// Verify
		Assert.areEqual('SELECT LeadSource FROM Lead GROUP BY LeadSource', soql, 'The generated rflib_SOQL should match the expected one.');
	}

	@IsTest
	static void groupByString() {
		// Test
		String soql = rflib_SOQL.of(Lead.SObjectType)
			.with(Lead.LeadSource)
			.groupBy('LeadSource')
			.toString();

		// Verify
		Assert.areEqual('SELECT LeadSource FROM Lead GROUP BY LeadSource', soql, 'The generated rflib_SOQL should match the expected one.');
	}

	@IsTest
	static void groupByRelated() {
		// Test
		String soql = rflib_SOQL.of(OpportunityLineItem.SObjectType)
			.count(OpportunityLineItem.Name, 'count')
			.groupBy('OpportunityLineItem.Opportunity.Account', Account.Id)
			.toString();

		// Verify
		Assert.areEqual('SELECT COUNT(Name) count FROM OpportunityLineItem GROUP BY OpportunityLineItem.Opportunity.Account.Id', soql, 'The generated rflib_SOQL should match the expected one.');
	}

	@IsTest
	static void groupByRelatedToAggregated() {
		// Setup
		insertAccounts();

		// Test
		List<AggregateResult> results = rflib_SOQL.of(Account.SObjectType)
			.count(Account.Name, 'names')
			.groupBy('Account.CreatedBy', User.Id)
			.toAggregated();

		// Verify
		Assert.areEqual(1, results.size(), 'Only one aggregated result should be returned, as the accounts were created by the same user.');
	}

	@IsTest
	static void groupByRelatedToAggregatedProxy() {
		// Setup
		insertAccounts();

		// Test
		List<rflib_SOQL.AggregateResultProxy> results = rflib_SOQL.of(Account.SObjectType)
			.count(Account.Name, 'names')
			.groupBy('Account.CreatedBy', User.Id)
			.toAggregatedProxy();

		// Verify
		Assert.areEqual(1, results.size(), 'Only one aggregated result should be returned, as the accounts were created by the same user.');
	}

	@IsTest
	static void groupByRollup() {
		// Test
		String soql = rflib_SOQL.of(Lead.SObjectType)
			.count(Lead.Name, 'cnt')
			.with(Lead.LeadSource)
			.groupByRollup(Lead.LeadSource)
			.toString();

		// Verify
		Assert.areEqual('SELECT LeadSource, COUNT(Name) cnt FROM Lead GROUP BY ROLLUP(LeadSource)', soql, 'The generated rflib_SOQL should match the expected one.');
	}

	@IsTest
	static void groupByRollupManyFields() {
		// Test
		String soql = rflib_SOQL.of(Lead.SObjectType)
			.count(Lead.Name, 'cnt')
			.with(Lead.Status, Lead.LeadSource)
			.groupByRollup(Lead.Status)
			.groupByRollup(Lead.LeadSource)
			.toString();

		// Verify
		Assert.areEqual('SELECT Status, LeadSource, COUNT(Name) cnt FROM Lead GROUP BY ROLLUP(Status, LeadSource)', soql, 'The generated rflib_SOQL should match the expected one.');
	}

	@IsTest
	static void groupByRollupRelated() {
		// Test
		String soql = rflib_SOQL.of(Lead.SObjectType)
			.count(Lead.Name, 'cnt')
			.groupByRollup('ConvertedOpportunity', Opportunity.StageName)
			.toString();

		// Verify
		Assert.areEqual('SELECT COUNT(Name) cnt FROM Lead GROUP BY ROLLUP(ConvertedOpportunity.StageName)', soql, 'The generated rflib_SOQL should match the expected one.');
	}

	@IsTest
	static void groupByCube() {
		// Test
		String soql = rflib_SOQL.of(Account.SObjectType)
			.with(Account.Type)
			.groupByCube(Account.Type)
			.toString();

		// Verify
		Assert.areEqual('SELECT Type FROM Account GROUP BY CUBE(Type)', soql, 'The generated rflib_SOQL should match the expected one.');
	}

	@IsTest
	static void groupByCubeManyFields() {
		// Test
		String soql = rflib_SOQL.of(Account.SObjectType)
			.with(Account.Type, Account.BillingCountry)
			.groupByCube(Account.Type)
			.groupByCube(Account.BillingCountry)
			.toString();

		// Verify
		Assert.areEqual('SELECT Type, BillingCountry FROM Account GROUP BY CUBE(Type, BillingCountry)', soql, 'The generated rflib_SOQL should match the expected one.');
	}

	@IsTest
	static void groupByCubeRelated() {
		// Test
		String soql = rflib_SOQL.of(Lead.SObjectType)
			.count(Lead.Name, 'cnt')
			.groupByCube('ConvertedOpportunity', Opportunity.StageName)
			.toString();

		// Verify
		Assert.areEqual('SELECT COUNT(Name) cnt FROM Lead GROUP BY CUBE(ConvertedOpportunity.StageName)', soql, 'The generated rflib_SOQL should match the expected one.');
	}

	@IsTest
	static void differentGroupByFunctionsException() {
		// Setup
		Exception queryException = null;

		// Test
		try {
		   rflib_SOQL.of(Account.SObjectType)
				.with(Account.Type)
				.groupBy(Account.Type)
				.groupByCube(Account.Type)
				.toString();
		} catch(Exception e) {
			queryException = e;
		}

		// Verify
		Assert.areEqual(
			'You can\'t use GROUP BY, GROUP BY ROLLUP and GROUP BY CUBE in the same query.',
			queryException.getMessage(),
			'The exception message should match the expected one.'
		);
	}

	@IsTest
	static void groupByWithDefaultFields() {
		// Test
		String soql = rflib_SOQL.of(Lead.SObjectType)
			.with(Lead.FirstName, Lead.LastName, Lead.Email)
			.with(Lead.LeadSource)
			.groupBy(Lead.LeadSource)
			.toString();

		// Verify
		Assert.areEqual('SELECT LeadSource FROM Lead GROUP BY LeadSource', soql, 'The generated rflib_SOQL should match the expected one.');
	}

	@IsTest
	static void groupByWithDefaultFieldsAndAggregateFunction() {
		// Test
		String soql = rflib_SOQL.of(Lead.SObjectType)
			.with(Lead.FirstName, Lead.LastName, Lead.Email)
			.count(Lead.Name)
			.with(Lead.LeadSource)
			.groupBy(Lead.LeadSource)
			.toString();

		// Verify
		Assert.areEqual('SELECT LeadSource, COUNT(Name) FROM Lead GROUP BY LeadSource', soql, 'The generated rflib_SOQL should match the expected one.');
	}

	@IsTest
	static void havingFilterWithSObjectField() {
		// Test
		String soql = rflib_SOQL.of(Lead.SObjectType)
			.count(Lead.Name)
			.groupBy(Lead.City)
			.have(rflib_SOQL.HavingFilter.with(Lead.City).startsWith('San'))
			.toString();

		// Verify
		Assert.areEqual('SELECT COUNT(Name) FROM Lead GROUP BY City HAVING City LIKE \'San%\'', soql, 'The generated rflib_SOQL should match the expected one.');
	}

	@IsTest
	static void havingFilterWithStringField() {
		// Test
		String soql = rflib_SOQL.of(Lead.SObjectType)
			.count(Lead.Name)
			.groupBy(Lead.City)
			.have(rflib_SOQL.HavingFilter.with('City').startsWith('San'))
			.toString();

		// Verify
		Assert.areEqual('SELECT COUNT(Name) FROM Lead GROUP BY City HAVING City LIKE \'San%\'', soql, 'The generated rflib_SOQL should match the expected one.');
	}

	@IsTest
	static void havingFilterCount() {
		// Test
		String soql = rflib_SOQL.of(Lead.SObjectType)
			.with(Lead.LeadSource)
			.count(Lead.Name)
			.groupBy(Lead.LeadSource)
			.have(rflib_SOQL.HavingFilter.count(Lead.Name).greaterThan(100))
			.toString();

		// Verify
		Assert.areEqual('SELECT LeadSource, COUNT(Name) FROM Lead GROUP BY LeadSource HAVING COUNT(Name) > 100', soql, 'The generated rflib_SOQL should match the expected one.');
	}

	@IsTest
	static void havingFilterAvg() {
		// Test
		String soql = rflib_SOQL.of(Lead.SObjectType)
			.with(Lead.LeadSource)
			.avg(Lead.Name)
			.groupBy(Lead.LeadSource)
			.have(rflib_SOQL.HavingFilter.avg(Lead.Name).greaterThan(100))
			.toString();

		// Verify
		Assert.areEqual('SELECT LeadSource, AVG(Name) FROM Lead GROUP BY LeadSource HAVING AVG(Name) > 100', soql, 'The generated rflib_SOQL should match the expected one.');
	}

	@IsTest
	static void havingFilterCountDistinct() {
		// Test
		String soql = rflib_SOQL.of(Lead.SObjectType)
			.with(Lead.LeadSource)
			.countDistinct(Lead.Name)
			.groupBy(Lead.LeadSource)
			.have(rflib_SOQL.HavingFilter.countDistinct(Lead.Name).greaterThan(100))
			.toString();

		// Verify
		Assert.areEqual('SELECT LeadSource, COUNT_DISTINCT(Name) FROM Lead GROUP BY LeadSource HAVING COUNT_DISTINCT(Name) > 100', soql, 'The generated rflib_SOQL should match the expected one.');
	}

	@IsTest
	static void havingFilterMin() {
		// Test
		String soql = rflib_SOQL.of(Lead.SObjectType)
			.with(Lead.LeadSource)
			.min(Lead.NumberOfEmployees)
			.groupBy(Lead.LeadSource)
			.have(rflib_SOQL.HavingFilter.min(Lead.NumberOfEmployees).greaterThan(100))
			.toString();

		// Verify
		Assert.areEqual('SELECT LeadSource, MIN(NumberOfEmployees) FROM Lead GROUP BY LeadSource HAVING MIN(NumberOfEmployees) > 100', soql, 'The generated rflib_SOQL should match the expected one.');
	}

	@IsTest
	static void havingFilterMax() {
		// Test
		String soql = rflib_SOQL.of(Lead.SObjectType)
			.with(Lead.LeadSource)
			.max(Lead.NumberOfEmployees)
			.groupBy(Lead.LeadSource)
			.have(rflib_SOQL.HavingFilter.max(Lead.NumberOfEmployees).greaterThan(100))
			.toString();

		// Verify
		Assert.areEqual('SELECT LeadSource, MAX(NumberOfEmployees) FROM Lead GROUP BY LeadSource HAVING MAX(NumberOfEmployees) > 100', soql, 'The generated rflib_SOQL should match the expected one.');
	}

	@IsTest
	static void havingFilterSum() {
		// Test
		String soql = rflib_SOQL.of(Lead.SObjectType)
			.with(Lead.LeadSource)
			.sum(Lead.AnnualRevenue)
			.groupBy(Lead.LeadSource)
			.have(rflib_SOQL.HavingFilter.sum(Lead.AnnualRevenue).greaterThan(100))
			.toString();

		// Verify
		Assert.areEqual('SELECT LeadSource, SUM(AnnualRevenue) FROM Lead GROUP BY LeadSource HAVING SUM(AnnualRevenue) > 100', soql, 'The generated rflib_SOQL should match the expected one.');
	}

	@IsTest
	static void havingFilterIsNull() {
		// Test
		String soql = rflib_SOQL.of(Lead.SObjectType)
			.count(Lead.Name)
			.groupBy(Lead.LeadSource)
			.have(rflib_SOQL.HavingFilter.with(Lead.LeadSource).isNull())
			.toString();

		// Verify
		Assert.areEqual('SELECT COUNT(Name) FROM Lead GROUP BY LeadSource HAVING LeadSource = null', soql, 'The generated rflib_SOQL should match the expected one.');
	}

	@IsTest
	static void havingFilterIsNotNull() {
		// Test
		String soql = rflib_SOQL.of(Lead.SObjectType)
			.with(Lead.LeadSource)
			.groupBy(Lead.LeadSource)
			.have(rflib_SOQL.HavingFilter.with(Lead.LeadSource).isNotNull())
			.toString();

		// Verify
		Assert.areEqual('SELECT LeadSource FROM Lead GROUP BY LeadSource HAVING LeadSource != null', soql, 'The generated rflib_SOQL should match the expected one.');
	}

	@IsTest
	static void havingFilterIsTrue() {
		// Test
		String soql = rflib_SOQL.of(Lead.SObjectType)
			.count(Lead.Name)
			.groupBy(Lead.IsConverted)
			.have(rflib_SOQL.HavingFilter.with(Lead.IsConverted).isTrue())
			.toString();

		// Verify
		Assert.areEqual('SELECT COUNT(Name) FROM Lead GROUP BY IsConverted HAVING IsConverted = true', soql, 'The generated rflib_SOQL should match the expected one.');
	}

	@IsTest
	static void havingFilterIsFalse() {
		// Test
		String soql = rflib_SOQL.of(Lead.SObjectType)
			.count(Lead.Name)
			.groupBy(Lead.IsConverted)
			.have(rflib_SOQL.HavingFilter.with(Lead.IsConverted).isFalse())
			.toString();

		// Verify
		Assert.areEqual('SELECT COUNT(Name) FROM Lead GROUP BY IsConverted HAVING IsConverted = false', soql, 'The generated rflib_SOQL should match the expected one.');
	}

	@IsTest
	static void havingFilterEqualString() {
		// Test
		String soql = rflib_SOQL.of(Lead.SObjectType)
			.count(Lead.Name)
			.groupBy(Lead.LeadSource)
			.have(rflib_SOQL.HavingFilter.with(Lead.LeadSource).equal('Web'))
			.toString();

		// Verify
		Assert.areEqual('SELECT COUNT(Name) FROM Lead GROUP BY LeadSource HAVING LeadSource = \'Web\'', soql, 'The generated rflib_SOQL should match the expected one.');
	}

	@IsTest
	static void havingFilterEqualInteger() {
		// Test
		String soql = rflib_SOQL.of(Lead.SObjectType)
			.count(Lead.Name)
			.groupBy(Lead.LeadSource)
			.have(rflib_SOQL.HavingFilter.sum(Lead.AnnualRevenue).equal(10000))
			.toString();

		// Verify
		Assert.areEqual('SELECT COUNT(Name) FROM Lead GROUP BY LeadSource HAVING SUM(AnnualRevenue) = 10000', soql, 'The generated rflib_SOQL should match the expected one.');
	}

	@IsTest
	static void havingFilterNotEqualString() {
		// Test
		String soql = rflib_SOQL.of(Lead.SObjectType)
			.count(Lead.Name)
			.groupBy(Lead.LeadSource)
			.have(rflib_SOQL.HavingFilter.with(Lead.LeadSource).notEqual('Web'))
			.toString();

		// Verify
		Assert.areEqual('SELECT COUNT(Name) FROM Lead GROUP BY LeadSource HAVING LeadSource != \'Web\'', soql, 'The generated rflib_SOQL should match the expected one.');
	}

	@IsTest
	static void havingFilterNotEqualInteger() {
		// Test
		String soql = rflib_SOQL.of(Lead.SObjectType)
			.count(Lead.Name)
			.groupBy(Lead.LeadSource)
			.have(rflib_SOQL.HavingFilter.sum(Lead.AnnualRevenue).notEqual(10000))
			.toString();

		// Verify
		Assert.areEqual('SELECT COUNT(Name) FROM Lead GROUP BY LeadSource HAVING SUM(AnnualRevenue) != 10000', soql, 'The generated rflib_SOQL should match the expected one.');
	}

	@IsTest
	static void havingFilterLessThan() {
		// Test
		String soql = rflib_SOQL.of(Lead.SObjectType)
			.count(Lead.Name)
			.groupBy(Lead.LeadSource)
			.have(rflib_SOQL.HavingFilter.sum(Lead.AnnualRevenue).lessThan(10000))
			.toString();

		// Verify
		Assert.areEqual('SELECT COUNT(Name) FROM Lead GROUP BY LeadSource HAVING SUM(AnnualRevenue) < 10000', soql, 'The generated rflib_SOQL should match the expected one.');
	}

	@IsTest
	static void havingFilterGreaterThan() {
		// Test
		String soql = rflib_SOQL.of(Lead.SObjectType)
			.count(Lead.Name)
			.groupBy(Lead.LeadSource)
			.have(rflib_SOQL.HavingFilter.sum(Lead.AnnualRevenue).greaterThan(10000))
			.toString();

		// Verify
		Assert.areEqual('SELECT COUNT(Name) FROM Lead GROUP BY LeadSource HAVING SUM(AnnualRevenue) > 10000', soql, 'The generated rflib_SOQL should match the expected one.');
	}

	@IsTest
	static void havingFilterLessOrEqual() {
		// Test
		String soql = rflib_SOQL.of(Lead.SObjectType)
			.count(Lead.Name)
			.groupBy(Lead.LeadSource)
			.have(rflib_SOQL.HavingFilter.sum(Lead.AnnualRevenue).lessOrEqual(10000))
			.toString();

		// Verify
		Assert.areEqual('SELECT COUNT(Name) FROM Lead GROUP BY LeadSource HAVING SUM(AnnualRevenue) <= 10000', soql, 'The generated rflib_SOQL should match the expected one.');
	}

	@IsTest
	static void havingFilterGreaterOrEqual() {
		// Test
		String soql = rflib_SOQL.of(Lead.SObjectType)
			.count(Lead.Name)
			.groupBy(Lead.LeadSource)
			.have(rflib_SOQL.HavingFilter.sum(Lead.AnnualRevenue).greaterOrEqual(10000))
			.toString();

		// Verify
		Assert.areEqual('SELECT COUNT(Name) FROM Lead GROUP BY LeadSource HAVING SUM(AnnualRevenue) >= 10000', soql, 'The generated rflib_SOQL should match the expected one.');
	}

	@IsTest
	static void havingFilterContains() {
		// Test
		String soql = rflib_SOQL.of(Lead.SObjectType)
			.sum(Lead.AnnualRevenue)
			.groupBy(Lead.City)
			.have(rflib_SOQL.HavingFilter.with(Lead.City).contains('San'))
			.toString();

		// Verify
		Assert.areEqual('SELECT SUM(AnnualRevenue) FROM Lead GROUP BY City HAVING City LIKE \'%San%\'', soql, 'The generated rflib_SOQL should match the expected one.');
	}

	@IsTest
	static void havingFilterCustomContains() {
		// Test
		String soql = rflib_SOQL.of(Lead.SObjectType)
			.sum(Lead.AnnualRevenue)
			.groupBy(Lead.City)
			.have(rflib_SOQL.HavingFilter.with(Lead.City).contains('_', 'San', '%'))
			.toString();

		// Verify
		Assert.areEqual('SELECT SUM(AnnualRevenue) FROM Lead GROUP BY City HAVING City LIKE \'_San%\'', soql, 'The generated rflib_SOQL should match the expected one.');
	}

	@IsTest
	static void havingFilterNotContains() {
		// Test
		String soql = rflib_SOQL.of(Lead.SObjectType)
			.sum(Lead.AnnualRevenue)
			.groupBy(Lead.City)
			.have(rflib_SOQL.HavingFilter.with(Lead.City).notContains('San'))
			.toString();

		// Verify
		Assert.areEqual('SELECT SUM(AnnualRevenue) FROM Lead GROUP BY City HAVING (NOT City LIKE \'%San%\')', soql, 'The generated rflib_SOQL should match the expected one.');
	}

	@IsTest
	static void havingFilterCustomNotContains() {
		// Test
		String soql = rflib_SOQL.of(Lead.SObjectType)
			.sum(Lead.AnnualRevenue)
			.groupBy(Lead.City)
			.have(rflib_SOQL.HavingFilter.with(Lead.City).notContains('_', 'San', '%'))
			.toString();

		// Verify
		Assert.areEqual('SELECT SUM(AnnualRevenue) FROM Lead GROUP BY City HAVING (NOT City LIKE \'_San%\')', soql, 'The generated rflib_SOQL should match the expected one.');
	}

	@IsTest
	static void havingFilterStartsWith() {
		// Test
		String soql = rflib_SOQL.of(Lead.SObjectType)
			.sum(Lead.AnnualRevenue)
			.groupBy(Lead.City)
			.have(rflib_SOQL.HavingFilter.with(Lead.City).startsWith('San'))
			.toString();

		// Verify
		Assert.areEqual('SELECT SUM(AnnualRevenue) FROM Lead GROUP BY City HAVING City LIKE \'San%\'', soql, 'The generated rflib_SOQL should match the expected one.');
	}

	@IsTest
	static void havingFilterNotStartsWith() {
		// Test
		String soql = rflib_SOQL.of(Lead.SObjectType)
			.sum(Lead.AnnualRevenue)
			.groupBy(Lead.City)
			.have(rflib_SOQL.HavingFilter.with(Lead.City).notStartsWith('San'))
			.toString();

		// Verify
		Assert.areEqual('SELECT SUM(AnnualRevenue) FROM Lead GROUP BY City HAVING (NOT City LIKE \'San%\')', soql, 'The generated rflib_SOQL should match the expected one.');
	}

	@IsTest
	static void havingFilterEndsWith() {
		// Test
		String soql = rflib_SOQL.of(Lead.SObjectType)
			.sum(Lead.AnnualRevenue)
			.groupBy(Lead.City)
			.have(rflib_SOQL.HavingFilter.with(Lead.City).endsWith('San'))
			.toString();

		// Verify
		Assert.areEqual('SELECT SUM(AnnualRevenue) FROM Lead GROUP BY City HAVING City LIKE \'%San\'', soql, 'The generated rflib_SOQL should match the expected one.');
	}

	@IsTest
	static void havingFilterNotEndsWith() {
		// Test
		String soql = rflib_SOQL.of(Lead.SObjectType)
			.sum(Lead.AnnualRevenue)
			.groupBy(Lead.City)
			.have(rflib_SOQL.HavingFilter.with(Lead.City).notEndsWith('San'))
			.toString();

		// Verify
		Assert.areEqual('SELECT SUM(AnnualRevenue) FROM Lead GROUP BY City HAVING (NOT City LIKE \'%San\')', soql, 'The generated rflib_SOQL should match the expected one.');
	}

	@IsTest
	static void havingFilterIsInSet() {
		// Test
		String soql = rflib_SOQL.of(Lead.SObjectType)
			.sum(Lead.AnnualRevenue)
			.groupBy(Lead.City)
			.have(rflib_SOQL.HavingFilter.with(Lead.City).isIn(new Set<String>{ 'San Francisco', 'Los Angeles' }))
			.toString();

		// Verify
		Assert.areEqual('SELECT SUM(AnnualRevenue) FROM Lead GROUP BY City HAVING City IN (\'San Francisco\', \'Los Angeles\')', soql, 'The generated rflib_SOQL should match the expected one.');
	}

	@IsTest
	static void havingFilterIsInList() {
		// Test
		String soql = rflib_SOQL.of(Lead.SObjectType)
			.sum(Lead.AnnualRevenue)
			.groupBy(Lead.City)
			.have(rflib_SOQL.HavingFilter.with(Lead.City).isIn(new List<String>{ 'San Francisco', 'Los Angeles' }))
			.toString();

		// Verify
		Assert.areEqual('SELECT SUM(AnnualRevenue) FROM Lead GROUP BY City HAVING City IN (\'San Francisco\', \'Los Angeles\')', soql, 'The generated rflib_SOQL should match the expected one.');
	}

	@IsTest
	static void havingFilterIsNotInSet() {
		// Test
		String soql = rflib_SOQL.of(Lead.SObjectType)
			.sum(Lead.AnnualRevenue)
			.groupBy(Lead.City)
			.have(rflib_SOQL.HavingFilter.with(Lead.City).notIn(new Set<String>{ 'San Francisco', 'Los Angeles' }))
			.toString();

		// Verify
		Assert.areEqual('SELECT SUM(AnnualRevenue) FROM Lead GROUP BY City HAVING City NOT IN (\'San Francisco\', \'Los Angeles\')', soql, 'The generated rflib_SOQL should match the expected one.');
	}

	@IsTest
	static void havingFilterIsNotInList() {
		// Test
		String soql = rflib_SOQL.of(Lead.SObjectType)
			.sum(Lead.AnnualRevenue)
			.groupBy(Lead.City)
			.have(rflib_SOQL.HavingFilter.with(Lead.City).notIn(new List<String>{ 'San Francisco', 'Los Angeles' }))
			.toString();

		// Verify
		Assert.areEqual('SELECT SUM(AnnualRevenue) FROM Lead GROUP BY City HAVING City NOT IN (\'San Francisco\', \'Los Angeles\')', soql, 'The generated rflib_SOQL should match the expected one.');
	}

	@IsTest
	static void havingFilterGroup() {
		// Test
		String soql = rflib_SOQL.of(Lead.SObjectType)
			.with(Lead.LeadSource)
			.count(Lead.Name)
			.groupBy(Lead.LeadSource)
			.groupBy(Lead.City)
			.have(rflib_SOQL.HavingFilterGroup
				.add(rflib_SOQL.HavingFilter.count(Lead.Name).greaterThan(100))
				.add(rflib_SOQL.HavingFilter.with(Lead.City).startsWith('San'))
			).toString();

		// Verify
		Assert.areEqual('SELECT LeadSource, COUNT(Name) FROM Lead GROUP BY LeadSource, City HAVING (COUNT(Name) > 100 AND City LIKE \'San%\')', soql, 'The generated rflib_SOQL should match the expected one.');
	}

	@IsTest
	static void dynamicHavingFilterGroup() {
		// Setup
		rflib_SOQL.HavingFilterGroup havingFilterGroup = rflib_SOQL.HavingFilterGroup;

		havingFilterGroup.add(rflib_SOQL.HavingFilter.count(Lead.Name).greaterThan(100));
		havingFilterGroup.add(rflib_SOQL.HavingFilter.with(Lead.City).startsWith('San'));

		// Test
		String soql = rflib_SOQL.of(Lead.SObjectType)
			.with(Lead.LeadSource)
			.count(Lead.Name)
			.groupBy(Lead.LeadSource)
			.groupBy(Lead.City)
			.have(havingFilterGroup)
			.toString();

		// Verify
		Assert.areEqual('SELECT LeadSource, COUNT(Name) FROM Lead GROUP BY LeadSource, City HAVING (COUNT(Name) > 100 AND City LIKE \'San%\')', soql, 'The generated rflib_SOQL should match the expected one.');
	}

	@IsTest
	static void dynamicHavingFilterGroupOnSoqlInstance() {
		// Test
		rflib_SOQL.Queryable builder = rflib_SOQL.of(Lead.SObjectType)
			.with(Lead.LeadSource)
			.count(Lead.Name)
			.groupBy(Lead.LeadSource)
			.groupBy(Lead.City)
			.have(rflib_SOQL.HavingFilter.with(Lead.LeadSource).equal('Web'));

		Assert.areEqual('SELECT LeadSource, COUNT(Name) FROM Lead GROUP BY LeadSource, City HAVING LeadSource = \'Web\'', builder.toString(), 'The generated rflib_SOQL should match the expected one.');

		builder.have(
			rflib_SOQL.HavingFilterGroup
				.add(rflib_SOQL.HavingFilter.count(Lead.Name).greaterThan(100))
				.add(rflib_SOQL.HavingFilter.with(Lead.City).startsWith('San'))
		);

		// Verify
		Assert.areEqual('SELECT LeadSource, COUNT(Name) FROM Lead GROUP BY LeadSource, City HAVING LeadSource = \'Web\' AND (COUNT(Name) > 100 AND City LIKE \'San%\')', builder.toString(), 'The generated rflib_SOQL should match the expected one.');
	}

	@IsTest
	static void multipleHavingFilterGroups() {
		// Test
		String soql = rflib_SOQL.of(Lead.SObjectType)
			.with(Lead.LeadSource)
			.count(Lead.Name)
			.groupBy(Lead.LeadSource)
			.groupBy(Lead.City)
			.have(rflib_SOQL.HavingFilterGroup.add(rflib_SOQL.HavingFilter.count(Lead.Name).greaterThan(1)))
			.have(rflib_SOQL.HavingFilterGroup.add(rflib_SOQL.HavingFilter.count(Lead.Name).greaterThan(2)))
			.have(rflib_SOQL.HavingFilterGroup.add(rflib_SOQL.HavingFilter.count(Lead.Name).greaterThan(3)))
			.have(rflib_SOQL.HavingFilterGroup.add(rflib_SOQL.HavingFilter.count(Lead.Name).greaterThan(4)))
			.have(rflib_SOQL.HavingFilterGroup.add(rflib_SOQL.HavingFilter.count(Lead.Name).greaterThan(5)))
			.have(rflib_SOQL.HavingFilterGroup.add(rflib_SOQL.HavingFilter.count(Lead.Name).greaterThan(6)))
			.have(rflib_SOQL.HavingFilterGroup.add(rflib_SOQL.HavingFilter.count(Lead.Name).greaterThan(7)))
			.have(rflib_SOQL.HavingFilterGroup.add(rflib_SOQL.HavingFilter.count(Lead.Name).greaterThan(8)))
			.have(rflib_SOQL.HavingFilterGroup.add(rflib_SOQL.HavingFilter.count(Lead.Name).greaterThan(9)))
			.have(rflib_SOQL.HavingFilterGroup.add(rflib_SOQL.HavingFilter.count(Lead.Name).greaterThan(10)))
			.have(rflib_SOQL.HavingFilterGroup.add(rflib_SOQL.HavingFilter.count(Lead.Name).greaterThan(11)))
			.anyHavingConditionMatching()
			.toString();

		// Verify
		Assert.areEqual(
			'SELECT LeadSource, COUNT(Name) FROM Lead GROUP BY LeadSource, City HAVING (COUNT(Name) > 1) OR (COUNT(Name) > 2) OR (COUNT(Name) > 3) OR (COUNT(Name) > 4) OR (COUNT(Name) > 5) OR (COUNT(Name) > 6) OR (COUNT(Name) > 7) OR (COUNT(Name) > 8) OR (COUNT(Name) > 9) OR (COUNT(Name) > 10) OR (COUNT(Name) > 11)',
			soql,
			'The generated rflib_SOQL should match the expected one.'
		);
	}

	@IsTest
	static void anyConditionMatchingForInnerHavingFilterGroups() {
		// Test
		String soql = rflib_SOQL.of(Lead.SObjectType)
			.with(Lead.LeadSource)
			.count(Lead.Name)
			.groupBy(Lead.LeadSource)
			.groupBy(Lead.City)
			.have(rflib_SOQL.HavingFilterGroup
				.add(rflib_SOQL.HavingFilter.count(Lead.Name).greaterThan(100))
				.add(rflib_SOQL.HavingFilter.with(Lead.City).startsWith('San'))
				.anyConditionMatching()
			).toString();

		// Verify
		Assert.areEqual('SELECT LeadSource, COUNT(Name) FROM Lead GROUP BY LeadSource, City HAVING (COUNT(Name) > 100 OR City LIKE \'San%\')', soql, 'The generated rflib_SOQL should match the expected one.');
	}

	@IsTest
	static void anyConditionMatchingForMainHavingFilterGroup() {
		// Test
		String soql = rflib_SOQL.of(Lead.SObjectType)
			.with(Lead.LeadSource)
			.count(Lead.Name)
			.groupBy(Lead.LeadSource)
			.groupBy(Lead.City)
			.have(rflib_SOQL.HavingFilter.count(Lead.Name).greaterThan(100))
			.have(rflib_SOQL.HavingFilter.with(Lead.City).startsWith('San'))
			.anyHavingConditionMatching()
			.toString();

		// Verify
		Assert.areEqual('SELECT LeadSource, COUNT(Name) FROM Lead GROUP BY LeadSource, City HAVING COUNT(Name) > 100 OR City LIKE \'San%\'', soql, 'The generated rflib_SOQL should match the expected one.');
	}

	@IsTest
	static void conditionLogicForMainHavingFilterGroup() {
		// Test
		String soql = rflib_SOQL.of(Lead.SObjectType)
			.with(Lead.LeadSource)
			.count(Lead.Name)
			.groupBy(Lead.LeadSource)
			.groupBy(Lead.City)
			.have(rflib_SOQL.HavingFilter.count(Lead.Name).greaterThan(100))
			.have(rflib_SOQL.HavingFilter.with(Lead.City).startsWith('San'))
			.havingConditionLogic('1 OR 2')
			.toString();

		// Verify
		Assert.areEqual('SELECT LeadSource, COUNT(Name) FROM Lead GROUP BY LeadSource, City HAVING COUNT(Name) > 100 OR City LIKE \'San%\'', soql, 'The generated rflib_SOQL should match the expected one.');
	}

	@IsTest
	static void nestedHavingFilterGroups() {
		// Test
		String soql = rflib_SOQL.of(Lead.SObjectType)
			.with(Lead.LeadSource)
			.count(Lead.Name)
			.groupBy(Lead.LeadSource)
			.have(rflib_SOQL.HavingFilterGroup
				.add(rflib_SOQL.HavingFilterGroup
					.add(rflib_SOQL.HavingFilter.count(Lead.Name).greaterThan(100))
					.add(rflib_SOQL.HavingFilter.count(Lead.Name).lessThan(200))
				)
				.add(rflib_SOQL.HavingFilterGroup
					.add(rflib_SOQL.HavingFilter.count(Lead.Name).greaterThan(400))
					.add(rflib_SOQL.HavingFilter.count(Lead.Name).lessThan(500))
				)
			).toString();

		// Verify
		Assert.areEqual(
			'SELECT LeadSource, COUNT(Name) FROM Lead GROUP BY LeadSource HAVING ((COUNT(Name) > 100 AND COUNT(Name) < 200) AND (COUNT(Name) > 400 AND COUNT(Name) < 500))',
			soql,
			'The generated rflib_SOQL should match the expected one.'
		);
	}

	@IsTest
	static void evaluateStringHavingCondition() {
		// Test
		String soql = rflib_SOQL.of(Lead.SObjectType)
			.with(Lead.LeadSource)
			.count(Lead.Name)
			.groupBy(Lead.LeadSource)
			.have('COUNT(Name) > 100 AND COUNT(Name) < 200')
			.toString();

		// Verify
		Assert.areEqual('SELECT LeadSource, COUNT(Name) FROM Lead GROUP BY LeadSource HAVING COUNT(Name) > 100 AND COUNT(Name) < 200', soql, 'The generated rflib_SOQL should match the expected one.');
	}

	@IsTest
	static void evaluateStringHavingConditionAndHavingFilterGroup() {
		// Test
		String soql = rflib_SOQL.of(Lead.SObjectType)
			.with(Lead.LeadSource)
			.count(Lead.Name)
			.groupBy(Lead.LeadSource)
			.have('(COUNT(Name) > 100 AND COUNT(Name) < 200)')
			.have(rflib_SOQL.HavingFilterGroup
				.add(rflib_SOQL.HavingFilter.count(Lead.Name).greaterThan(400))
				.add(rflib_SOQL.HavingFilter.count(Lead.Name).lessThan(500))
			).toString();

		// Verify
		Assert.areEqual(
			'SELECT LeadSource, COUNT(Name) FROM Lead GROUP BY LeadSource HAVING (COUNT(Name) > 100 AND COUNT(Name) < 200) AND (COUNT(Name) > 400 AND COUNT(Name) < 500)',
			soql,
			'The generated rflib_SOQL should match the expected one.'
		);
	}

	@IsTest
	static void evaluateStringInHavingFilterGroupAndHavingFilter() {
		// Test
		String soql = rflib_SOQL.of(Lead.SObjectType)
			.with(Lead.LeadSource)
			.count(Lead.Name)
			.groupBy(Lead.LeadSource)
			.have(rflib_SOQL.HavingFilterGroup
				.add('(COUNT(Name) > 100 AND COUNT(Name) < 200)')
				.add(rflib_SOQL.HavingFilter.count(Lead.Name).lessThan(500))
			).toString();

		// Verify
		Assert.areEqual(
			'SELECT LeadSource, COUNT(Name) FROM Lead GROUP BY LeadSource HAVING ((COUNT(Name) > 100 AND COUNT(Name) < 200) AND COUNT(Name) < 500)',
			soql,
			'The generated rflib_SOQL should match the expected one.'
		);
	}

	// WITH DATA CATEGORY

	@IsTest
	static void dataCategoryFilterWithStringField() {
		// Test
		String soql = rflib_SOQL.of('Knowledge__kav')
			.with('Title')
			.withDataCategory(rflib_SOQL.DataCategoryFilter.with('Geography__c').aboveOrBelow('Europe__c'))
			.toString();

		// Verify
		Assert.areEqual('SELECT Title FROM Knowledge__kav WITH DATA CATEGORY Geography__c ABOVE_OR_BELOW Europe__c', soql, 'The generated rflib_SOQL should match the expected one.');
	}

	@IsTest
	static void dataCategoryFilterAt() {
		// Test
		String soql = rflib_SOQL.of('Knowledge__kav')
			.with('Title')
			.withDataCategory(rflib_SOQL.DataCategoryFilter.with('Geography__c').at('Europe__c'))
			.toString();

		// Verify
		Assert.areEqual('SELECT Title FROM Knowledge__kav WITH DATA CATEGORY Geography__c AT Europe__c', soql, 'The generated rflib_SOQL should match the expected one.');
	}

	@IsTest
	static void dataCategoryFilterAtMultiple() {
		// Test
		String soql = rflib_SOQL.of('Knowledge__kav')
			.with('Title')
			.withDataCategory(rflib_SOQL.DataCategoryFilter.with('Geography__c').at(new List<String>{ 'Europe__c', 'North_America__c' }))
			.toString();

		// Verify
		Assert.areEqual('SELECT Title FROM Knowledge__kav WITH DATA CATEGORY Geography__c AT (Europe__c, North_America__c)', soql, 'The generated rflib_SOQL should match the expected one.');
	}

	@IsTest
	static void dataCategoryFilterAbove() {
		// Test
		String soql = rflib_SOQL.of('Knowledge__kav')
			.with('Title')
			.withDataCategory(rflib_SOQL.DataCategoryFilter.with('Geography__c').above('Europe__c'))
			.toString();

		// Verify
		Assert.areEqual('SELECT Title FROM Knowledge__kav WITH DATA CATEGORY Geography__c ABOVE Europe__c', soql, 'The generated rflib_SOQL should match the expected one.');
	}

	@IsTest
	static void dataCategoryFilterAboveMultiple() {
		// Test
		String soql = rflib_SOQL.of('Knowledge__kav')
			.with('Title')
			.withDataCategory(rflib_SOQL.DataCategoryFilter.with('Geography__c').above(new List<String>{ 'Europe__c', 'North_America__c' }))
			.toString();

		// Verify
		Assert.areEqual('SELECT Title FROM Knowledge__kav WITH DATA CATEGORY Geography__c ABOVE (Europe__c, North_America__c)', soql, 'The generated rflib_SOQL should match the expected one.');
	}

	@IsTest
	static void dataCategoryFilterBelow() {
		// Test
		String soql = rflib_SOQL.of('Knowledge__kav')
			.with('Title')
			.withDataCategory(rflib_SOQL.DataCategoryFilter.with('Geography__c').below('Europe__c'))
			.toString();

		// Verify
		Assert.areEqual('SELECT Title FROM Knowledge__kav WITH DATA CATEGORY Geography__c BELOW Europe__c', soql, 'The generated rflib_SOQL should match the expected one.');
	}

	@IsTest
	static void dataCategoryFilterBelowMultiple() {
		// Test
		String soql = rflib_SOQL.of('Knowledge__kav')
			.with('Title')
			.withDataCategory(rflib_SOQL.DataCategoryFilter.with('Geography__c').below(new List<String>{ 'Europe__c', 'North_America__c' }))
			.toString();

		// Verify
		Assert.areEqual('SELECT Title FROM Knowledge__kav WITH DATA CATEGORY Geography__c BELOW (Europe__c, North_America__c)', soql, 'The generated rflib_SOQL should match the expected one.');
	}

	@IsTest
	static void dataCategoryFilterAboveOrBelow() {
		// Test
		String soql = rflib_SOQL.of('Knowledge__kav')
			.with('Title')
			.withDataCategory(rflib_SOQL.DataCategoryFilter.with('Geography__c').aboveOrBelow('Europe__c'))
			.toString();

		// Verify
		Assert.areEqual('SELECT Title FROM Knowledge__kav WITH DATA CATEGORY Geography__c ABOVE_OR_BELOW Europe__c', soql, 'The generated rflib_SOQL should match the expected one.');
	}

	@IsTest
	static void dataCategoryFilterAboveOrBelowMultiple() {
		// Test
		String soql = rflib_SOQL.of('Knowledge__kav')
			.with('Title')
			.withDataCategory(rflib_SOQL.DataCategoryFilter.with('Geography__c').aboveOrBelow(new List<String>{ 'Europe__c', 'North_America__c' }))
			.toString();

		// Verify
		Assert.areEqual('SELECT Title FROM Knowledge__kav WITH DATA CATEGORY Geography__c ABOVE_OR_BELOW (Europe__c, North_America__c)', soql, 'The generated rflib_SOQL should match the expected one.');
	}

	@IsTest
	static void dataCategoryWithMultipleDataCategoryFilters() {
		// Test
		String soql = rflib_SOQL.of('Knowledge__kav')
			.with('Title')
			.withDataCategory(rflib_SOQL.DataCategoryFilter.with('Geography__c').aboveOrBelow(new List<String>{ 'Europe__c', 'North_America__c' }))
			.withDataCategory(rflib_SOQL.DataCategoryFilter.with('Product__c').at(new List<String>{ 'Product1__c', 'Product2__c' }))
			.toString();

		// Verify
		Assert.areEqual('SELECT Title FROM Knowledge__kav WITH DATA CATEGORY Geography__c ABOVE_OR_BELOW (Europe__c, North_America__c) AND Product__c AT (Product1__c, Product2__c)', soql, 'The generated rflib_SOQL should match the expected one.');
	}

	@IsTest
	static void dataCategoryWithMultipleFilters() {
		// Test
		String soql = rflib_SOQL.of('Knowledge__kav')
			.with('Title')
			.whereAre(rflib_SOQL.Filter.with('PublishStatus').equal('Draft'))
			.whereAre(rflib_SOQL.Filter.with('Language').equal('en_US'))
			.withDataCategory(rflib_SOQL.DataCategoryFilter.with('Geography__c').aboveOrBelow(new List<String>{ 'Europe__c', 'North_America__c' }))
			.withDataCategory(rflib_SOQL.DataCategoryFilter.with('Product__c').at('Product1__c'))
			.toString();

		// Verify
		Assert.areEqual('SELECT Title FROM Knowledge__kav WHERE PublishStatus = :v1 AND Language = :v2 WITH DATA CATEGORY Geography__c ABOVE_OR_BELOW (Europe__c, North_America__c) AND Product__c AT Product1__c', soql, 'The generated rflib_SOQL should match the expected one.');
	}

	// ORDER BY

	@IsTest
	static void orderByString() {
		// Test
		String soql = rflib_SOQL.of(Account.SObjectType)
			.orderBy('Industry').sortDesc().nullsLast()
			.orderBy('Id')
			.toString();

		// Verify
		Assert.areEqual('SELECT Id FROM Account ORDER BY Industry DESC NULLS LAST, Id ASC NULLS FIRST', soql, 'The generated rflib_SOQL should match the expected one.');
	}

	@IsTest
	static void orderByDynamic() {
		// Test
		String soql = rflib_SOQL.of(Account.SObjectType)
			.orderBy('Industry', 'ASC')
			.toString();

		// Verify
		Assert.areEqual('SELECT Id FROM Account ORDER BY Industry ASC NULLS FIRST', soql, 'The generated rflib_SOQL should match the expected one.');
	}

	@IsTest
	static void dynamicNullsOrder() {
		// Test
		String soql = rflib_SOQL.of(Account.SObjectType)
			.orderBy('Industry')
			.nullsOrder('LAST')
			.toString();

		// Verify
		Assert.areEqual('SELECT Id FROM Account ORDER BY Industry ASC NULLS LAST', soql, 'The generated rflib_SOQL should match the expected one.');
	}

	@IsTest
	static void orderByDynamicWithSort() {
		// Test
		String soql = rflib_SOQL.of(Account.SObjectType)
			.orderBy('Industry')
			.sort('ASC')
			.toString();

		// Verify
		Assert.areEqual('SELECT Id FROM Account ORDER BY Industry ASC NULLS FIRST', soql, 'The generated rflib_SOQL should match the expected one.');
	}

	@IsTest
	static void orderBy() {
		// Test
		String soql = rflib_SOQL.of(Account.SObjectType)
			.orderBy(Account.Industry).sortDesc().nullsLast()
			.orderBy(Account.Id)
			.toString();

		// Verify
		Assert.areEqual('SELECT Id FROM Account ORDER BY Industry DESC NULLS LAST, Id ASC NULLS FIRST', soql, 'The generated rflib_SOQL should match the expected one.');
	}

	@IsTest
	static void orderByRelated() {
		// Test
		String soql = rflib_SOQL.of(Contact.SObjectType)
			.orderBy('Account', Account.Name)
			.toString();

		// Verify
		Assert.areEqual('SELECT Id FROM Contact ORDER BY Account.Name ASC NULLS FIRST', soql, 'The generated rflib_SOQL should match the expected one.');
	}

	@IsTest
	static void orderByCount() {
		// Test
		String soql = rflib_SOQL.of(Account.SObjectType)
			.with(Account.Industry)
			.groupBy(Account.Industry)
			.orderByCount(Account.Industry).sortDesc().nullsLast()
			.toString();

		// Verify
		Assert.areEqual('SELECT Industry FROM Account GROUP BY Industry ORDER BY COUNT(Industry) DESC NULLS LAST', soql, 'The generated rflib_SOQL should match the expected one.');
	}

	@IsTest
	static void setLimit() {
		// Test
		String soql = rflib_SOQL.of(Account.SObjectType)
			.setLimit(100)
			.toString();

		// Verify
		Assert.areEqual('SELECT Id FROM Account LIMIT 100', soql, 'The generated rflib_SOQL should match the expected one.');
	}

	@IsTest
	static void offset() {
		// Test
		String soql = rflib_SOQL.of(Account.SObjectType)
			.offset(100)
			.toString();

		// Verify
		Assert.areEqual('SELECT Id FROM Account OFFSET 100', soql, 'The generated rflib_SOQL should match the expected one.');
	}

	@IsTest
	static void forReference() {
		// Test
		String soql = rflib_SOQL.of(Account.SObjectType)
			.forReference()
			.toString();

		// Verify
		Assert.areEqual('SELECT Id FROM Account FOR REFERENCE', soql, 'The generated rflib_SOQL should match the expected one.');
	}

	@IsTest
	static void forView() {
		// Test
		String soql = rflib_SOQL.of(Account.SObjectType)
			.forView()
			.toString();

		// Verify
		Assert.areEqual('SELECT Id FROM Account FOR VIEW', soql, 'The generated rflib_SOQL should match the expected one.');
	}

	@IsTest
	static void forUpdate() {
		// Test
		String soql = rflib_SOQL.of(Account.SObjectType)
			.forUpdate()
			.toString();

		// Verify
		Assert.areEqual('SELECT Id FROM Account FOR UPDATE', soql, 'The generated rflib_SOQL should match the expected one.');
	}

	@IsTest
	static void allRows() {
		// Test
		String soql = rflib_SOQL.of(Account.SObjectType)
			.allRows()
			.toString();

		// Verify
		Assert.areEqual('SELECT Id FROM Account ALL ROWS', soql, 'The generated rflib_SOQL should match the expected one.');
	}

	@IsTest
	static void byId() {
		// Setup
		Id fakeAccountId = rflib_SOQL.IdGenerator.get(Account.SObjectType);

		// Test
		rflib_SOQL.Queryable builder = rflib_SOQL.of(Account.SObjectType).byId(fakeAccountId);

		// Verify
		String soql = builder.toString();
		Assert.areEqual('SELECT Id FROM Account WHERE Id = :v1', soql, 'The generated rflib_SOQL should match the expected one.');

		Map<String, Object> binding = builder.binding();
		Assert.areEqual(fakeAccountId, binding.get('v1'), 'The binding variable should match the expected value.');
	}

	@IsTest
	static void byIdSObject() {
		// Setup
		List<Case> cases = insertCases();

		// Test
		rflib_SOQL.Queryable builder = rflib_SOQL.of(Case.SObjectType).byId(cases[0]);

		// Verify
		String soql = builder.toString();
		Assert.areEqual('SELECT Id FROM Case WHERE Id = :v1', soql, 'The generated rflib_SOQL should match the expected one.');

		Map<String, Object> binding = builder.binding();
		Assert.areEqual(cases[0].Id, binding.get('v1'), 'The binding variable should match the expected value.');
	}

	@IsTest
	static void byIdsSet() {
		// Verify
		Set<Id> accountIds = new Set<Id>{ rflib_SOQL.IdGenerator.get(Account.SObjectType) };

		// Test
		rflib_SOQL.Queryable builder = rflib_SOQL.of(Account.SObjectType).byIds(accountIds);

		// Verify
		String soql = builder.toString();
		Assert.areEqual('SELECT Id FROM Account WHERE Id IN :v1', soql, 'The generated rflib_SOQL should match the expected one.');

		Map<String, Object> binding = builder.binding();
		Assert.areEqual(accountIds, binding.get('v1'), 'The binding variable should match the expected value.');
	}

	@IsTest
	static void byIdsList() {
		// Setup
		List<Id> accountIds = new List<Id>{ rflib_SOQL.IdGenerator.get(Account.SObjectType) };

		// Test
		rflib_SOQL.Queryable builder = rflib_SOQL.of(Account.SObjectType).byIds(accountIds);

		// Verify
		String soql = builder.toString();
		Assert.areEqual('SELECT Id FROM Account WHERE Id IN :v1', soql, 'The generated rflib_SOQL should match the expected one.');

		Map<String, Object> binding = builder.binding();
		Assert.areEqual(accountIds, binding.get('v1'), 'The binding variable should match the expected value.');
	}

	@IsTest
	static void byIdsSObjects() {
		// Setup
		List<Case> cases = insertCases();

		// Test
		rflib_SOQL.Queryable builder = rflib_SOQL.of(Case.SObjectType).byIds(cases);

		// Verify
		String soql = builder.toString();
		Assert.areEqual('SELECT Id FROM Case WHERE Id IN :v1', soql, 'The generated rflib_SOQL should match the expected one.');

		Map<String, Object> binding = builder.binding();
		Assert.areEqual(cases, binding.get('v1'), 'The binding variable should match the expected value.');
	}

	@IsTest
	static void byRecordType() {
		// Setup
		String recordTypeDeveloperName = 'Partner';

		// Test
		rflib_SOQL.Queryable builder = rflib_SOQL.of(Account.SObjectType).byRecordType(recordTypeDeveloperName);

		// Verify
		String soql = builder.toString();
		Assert.areEqual('SELECT Id FROM Account WHERE RecordType.DeveloperName = :v1', soql, 'The generated rflib_SOQL should match the expected one.');

		Map<String, Object> binding = builder.binding();
		Assert.areEqual(recordTypeDeveloperName, binding.get('v1'), 'The binding variable should match the expected value.');
	}

	@IsTest
	static void toObjectWithoutSharing() {
		// Setup
		Case testCase = new Case(Status = 'New', Origin = 'Web');
		insert testCase;

		System.runAs(minimumAccessUser()) {
			// Test
			Case resultCase = (Case) rflib_SOQL.of(Case.SObjectType).systemMode().withoutSharing().toObject();

			// Verify
			Assert.areEqual(testCase.Id, resultCase.Id, 'The case should be returned even if the user does not have access to it.');
		}
	}

	@IsTest
	static void toListWithoutSharing() {
		// Setup
		insertCases();

		System.runAs(minimumAccessUser()) {
			// Test
			List<Case> cases = rflib_SOQL.of(Case.SObjectType).systemMode().withoutSharing().toList();

			// Verify
			Assert.areEqual(2, cases.size(), 'Cases should be returned even if the user does not have access to them.');
		}
	}

	@IsTest
	static void toIntegerWithoutSharing() {
		// Setup
		insertCases();

		System.runAs(minimumAccessUser()) {
			// Test
			Integer casesAmount = rflib_SOQL.of(Case.SObjectType).count().systemMode().withoutSharing().toInteger();

			// Verify
			Assert.areEqual(2, casesAmount, 'The amount of two cases should be returned even if the user does not have access to them.');
		}
	}

	@IsTest
	static void toObjectWithSharing() {
		// Setup
		insert new Task(Subject = 'Test', Type = 'Other');

		System.runAs(minimumAccessUser()) {
			// Test
			Task resultTask = (Task) rflib_SOQL.of(Task.SObjectType).systemMode().withSharing().toObject();

			// Verify
			Assert.isNull(resultTask, 'The user should not have access to the task.');
		}
	}

	@IsTest
	static void toListWithSharing() {
		// Setup
		insertTasks();

		System.runAs(minimumAccessUser()) {
			// Test
			List<Task> tasks = rflib_SOQL.of(Task.SObjectType).systemMode().withSharing().toList();

			// Verify
			Assert.areEqual(0, tasks.size(), 'The user should not have access to the tasks.');
		}
	}

	@IsTest
	static void toIntegerWithSharing() {
		insertTasks();

		System.runAs(minimumAccessUser()) {
			// Test
			Integer tasksAmount = rflib_SOQL.of(Task.SObjectType).count().systemMode().withSharing().toInteger();

			// Verify
			Assert.areEqual(0, tasksAmount, 'The user should not have access to the tasks.');
		}
	}

	@IsTest
	static void userMode() {
		// Setup
		insert new Task(Subject = 'Test', Type = 'Other');

		System.runAs(minimumAccessUser()) {
			// Test
			Exception queryException = null;

			try {
				rflib_SOQL.of(Task.SObjectType)
					.with(Task.Type)
					.userMode()
					.toObject();
			} catch(Exception e) {
				queryException = e;
			}

			// Verify
			Assert.isTrue(queryException.getMessage().contains('No such column \'Type\' on entity \'Task\'.'), 'The user should not have access to the \'Type\' field.');
		}
	}

	@IsTest
	static void stripInaccessibleToObject() {
		// Setup
		insert new Task(Subject = 'Test', Type = 'Other');

		System.runAs(minimumAccessUser()) {
			// Test
			Task task = (Task) rflib_SOQL.of(Task.SObjectType)
				.with(Task.Type)
				.systemMode()
				.stripInaccessible()
				.withoutSharing()
				.toObject();

			Exception queryException = null;

			String inaccessibleFieldValue;

			try {
				inaccessibleFieldValue = task.Type;
			} catch(Exception e) {
				queryException = e;
			}

			// Verify
			Assert.areEqual(
				'SObject row was retrieved via SOQL without querying the requested field: Task.Type',
				queryException.getMessage(),
				'The user should not have access to the \'Type\' field.'
			);
		}
	}

	@IsTest
	static void stripInaccessibleToList() {
		// Setup
		insertTasks();

		System.runAs(minimumAccessUser()) {
			// Test
			List<Task> tasks = rflib_SOQL.of(Task.SObjectType)
				.with(Task.Type)
				.systemMode()
				.stripInaccessible()
				.withoutSharing()
				.toList();

			Exception queryException = null;

			String inaccessibleFieldValue;

			try {
				inaccessibleFieldValue = tasks[0].Type;
			} catch(Exception e) {
				queryException = e;
			}

			// Verify
			Assert.areEqual(
				'SObject row was retrieved via SOQL without querying the requested field: Task.Type',
				queryException.getMessage(),
				'The user should not have access to the \'Type\' field.'
			);
		}
	}

	@IsTest
	static void stripInaccessibleToAggregated() {
		// Setup
		insertTasks();

		System.runAs(minimumAccessUser()) {
			// Test
			Exception queryException = null;

			try {
				Set<String> taskTypes = rflib_SOQL.of(Task.SObjectType)
					.with(Task.Type)
					.systemMode()
					.stripInaccessible()
					.withoutSharing()
					.toValuesOf(Task.Type);
			} catch(Exception e) {
				queryException = e;
			}

			// Verify
			Assert.areEqual(
				'AggregateResult SObject types are not supported',
				queryException.getMessage(),
				'The user should not have access to the \'Type\' field.'
			);
		}
	}

	@IsTest
	static void mockId() {
		// Setup
		List<Account> accounts = new List<Account>{
			new Account(Name = 'Test 1'),
			new Account(Name = 'Test 2')
		};

		// Test
		rflib_SOQL.setMock('mockingQuery', accounts);
		List<Account> result = rflib_SOQL.of(Account.SObjectType).with(Account.Name).mockId('mockingQuery').toList();

		// Verify
		Assert.areEqual(accounts, result, 'The mocked accounts should be returned.');
	}

	@IsTest
	static void mockIdSpecifiedButQueryNotMocked() {
		// Test
		List<Account> accounts = rflib_SOQL.of(Account.SObjectType).with(Account.Name).mockId('mockingQuery').toList();

		// Verify
		Assert.areEqual(0, accounts.size(), 'The mocked accounts should be returned.');
	}

	@IsTest
	static void mockingSingleRecord() {
		// Setup
		Account testAccount = new Account(Name = 'Test 1');

		// Test
		rflib_SOQL.setMock('mockingQuery', testAccount);
		Account result = (Account) rflib_SOQL.of(Account.SObjectType).with(Account.Name).mockId('mockingQuery').toObject();

		// Verify
		Assert.areEqual(testAccount, result, 'The mocked account should be returned.');
	}

	@IsTest
	static void mockNoResult() {
		// Test
		rflib_SOQL.setMock('mockingQuery', new List<Account>());
		Account result = (Account) rflib_SOQL.of(Account.SObjectType).with(Account.Name).mockId('mockingQuery').toObject();

		// Verify
		Assert.isNull(result, 'The result should be null when no records are mocked.');
	}

	@IsTest
	static void mockNoResultWithNull() {
		// Test
		rflib_SOQL.setMock('mockingQuery', (Account) null);
		Account result = (Account) rflib_SOQL.of(Account.SObjectType).with(Account.Name).mockId('mockingQuery').toObject();

		// Verify
		Assert.isNull(result, 'The result should be null when no records are mocked.');
	}

	@IsTest
	static void mockNoResults() {
		// Test
		rflib_SOQL.mock('mockingQuery').thenReturn(new List<Account>());
		List<Account> result = rflib_SOQL.of(Account.SObjectType).with(Account.Name).mockId('mockingQuery').toList();

		// Verify
		Assert.isTrue(result.isEmpty(), 'The result should be empty when no records are mocked.');
	}

	@IsTest
	static void mockingMultipleRecords() {
		// Setup
		List<Account> testAccounts = new List<Account>{
			new Account(Name = 'Test 1'),
			new Account(Name = 'Test 2')
		};

		// Test
		rflib_SOQL.setMock('mockingQuery', testAccounts);
		List<Account> result = rflib_SOQL.of(Account.SObjectType).with(Account.Name).mockId('mockingQuery').toList();

		// Verify
		Assert.areEqual(testAccounts, result, 'The mocked accounts should be returned.');
	}

	@IsTest
	static void mockingSingleRecordWithMockableInterface() {
		// Setup
		Account testAccount = new Account(Name = 'Test 1');

		// Test
		rflib_SOQL.mock('mockingQuery').thenReturn(testAccount);
		Account result = (Account) rflib_SOQL.of(Account.SObjectType).with(Account.Name).mockId('mockingQuery').toObject();

		// Verify
		Assert.areEqual(testAccount.Name, result.Name, 'The result account Name should be the same as the mocked account Name.');
		Assert.isNotNull(result.Id, 'The result account Id should be always set even if the mocked account Id is not set.');
	}

	@IsTest
	static void mockingQueryException() {
		// Test
		rflib_SOQL.mock('mockingQuery').throwException();

		Exception queryException = null;

		try {
			Account result = (Account) rflib_SOQL.of(Account.SObjectType).with(Account.Name).mockId('mockingQuery').toObject();
		} catch (QueryException e) {
			queryException = e;
		}

		// Verify
		Assert.isNotNull(queryException, 'The query exception should be thrown, because it\'s mocked.');
		Assert.areEqual('List has no rows for assignment to SObject', queryException.getMessage(), 'The query exception should be thrown.');
	}

	@IsTest
	static void mockingQueryExceptionWithMessage() {
		// Test
		String message = 'No such column \'Name\' on entity \'Account\'.';
		rflib_SOQL.mock('mockingQuery').throwException(message);

		Exception queryException = null;

		try {
			Account result = (Account) rflib_SOQL.of(Account.SObjectType).with(Account.Name).mockId('mockingQuery').toObject();
		} catch (QueryException e) {
			queryException = e;
		}

		// Verify
		Assert.isNotNull(queryException, 'The query exception should be thrown, because it\'s mocked.');
		Assert.areEqual(message, queryException.getMessage(), 'The query exception should be thrown.');
	}

	@IsTest
	static void mockingCount() {
		// Test
		rflib_SOQL.setCountMock('mockingQuery', 2);
		Integer result = rflib_SOQL.of(Account.SObjectType).count().mockId('mockingQuery').toInteger();

		// Verify
		Assert.areEqual(2, result, 'The mocked count should be returned.');
	}

	@IsTest
	static void mockingCountWithMockableInterface() {
		// Test
		rflib_SOQL.mock('mockingQuery').thenReturn(2);
		Integer result = rflib_SOQL.of(Account.SObjectType).count().mockId('mockingQuery').toInteger();

		// Verify
		Assert.areEqual(2, result, 'The mocked count should be returned.');
	}

	@IsTest
	static void mockWithManyPlainFields() {
		// Setup
		List<Account> accounts = new List<Account>{
			new Account(Name = 'Test 1', Description = 'Test 1 Description', Website = 'www.beyondthecloud.dev'),
			new Account(Name = 'Test 2', Description = 'Test 2 Description', Website = 'www.beyondthecloud.dev')
		};

		// Test
		rflib_SOQL.mock('mockingQuery').thenReturn(accounts);
		List<Account> result = rflib_SOQL.of(Account.SObjectType).with(Account.Name).mockId('mockingQuery').toList();

		// Verify
		Assert.areEqual(accounts.size(), result.size(), 'The result accounts size should be the same size of mocked accounts.');

		for (Account mockedResult : result) {
			Assert.isTrue(mockedResult.isSet(Account.Name), 'Only Account Name should be set.');
			Assert.isNull(mockedResult.Description, 'The Account Description should not be set because it was not included in the SELECT clause.');
			Assert.isNull(mockedResult.Website, 'The Account Website should not be set because it was not included in the SELECT clause.');
		}
	}

	@IsTest
	static void mockWithManyPlainFieldsWithId() {
		// Setup
		List<Account> accounts = new List<Account>{
			new Account(Id = rflib_SOQL.IdGenerator.get(Account.SObjectType), Name = 'Test 1', Description = 'Test 1 Description', Website = 'www.beyondthecloud.dev'),
			new Account(Id = rflib_SOQL.IdGenerator.get(Account.SObjectType), Name = 'Test 2', Description = 'Test 2 Description', Website = 'www.beyondthecloud.dev')
		};

		// Test
		rflib_SOQL.mock('mockingQuery').thenReturn(accounts);
		List<Account> result = rflib_SOQL.of(Account.SObjectType).with(Account.Id, Account.Name).mockId('mockingQuery').toList();

		// Verify
		Assert.areEqual(accounts.size(), result.size(), 'The result accounts size should be the same size of mocked accounts.');

		for (Account mockedResult : result) {
			Assert.isTrue(mockedResult.isSet(Account.Id), 'Only Account Id should be set.');
			Assert.isTrue(mockedResult.isSet(Account.Name), 'Only Account Name should be set.');
			Assert.isNull(mockedResult.Description, 'The Account Description should not be set because it was not included in the SELECT clause.');
			Assert.isNull(mockedResult.Website, 'The Account Website should not be set because it was not included in the SELECT clause.');
		}
	}

	@IsTest
	static void mockWithManyPlainFieldsAndSelectNotMockedField() {
		// Setup
		List<Account> accounts = new List<Account>{
			new Account(Name = 'Test 1', Description = 'Test 1 Description', Website = 'www.beyondthecloud.dev'),
			new Account(Name = 'Test 2', Description = 'Test 2 Description', Website = 'www.beyondthecloud.dev')
		};

		// Test
		rflib_SOQL.mock('mockingQuery').thenReturn(accounts);
		List<Account> result = rflib_SOQL.of(Account.SObjectType).with(Account.Industry).mockId('mockingQuery').toList();

		// Verify
		Assert.areEqual(accounts.size(), result.size(), 'The result accounts size should be the same size of mocked accounts.');

		for (Account mockedResult : result) {
			Assert.isTrue(mockedResult.isSet(Account.Industry), 'Only Account Industry should be set.');
			Assert.isNull(mockedResult.Industry, 'The Account Industry should be null because it was not specify in mocked records.');
			Assert.isNull(mockedResult.Name, 'The Account Name should not be set because it was not included in the SELECT clause.');
			Assert.isNull(mockedResult.Description, 'The Account Description should not be set because it was not included in the SELECT clause.');
			Assert.isNull(mockedResult.Website, 'The Account Website should not be set because it was not included in the SELECT clause.');
		}
	}

	@IsTest
	static void mockWithManyFieldAndSelectToLabel() {
		// Setup
		List<Account> accounts = new List<Account>{
			new Account(Name = 'Test 1', Description = 'Test 1 Description', Website = 'www.beyondthecloud.dev'),
			new Account(Name = 'Test 2', Description = 'Test 2 Description', Website = 'www.beyondthecloud.dev')
		};

		// Test
		rflib_SOQL.mock('mockingQuery').thenReturn(accounts);
		List<Account> result = rflib_SOQL.of(Account.SObjectType).with(Account.Name).toLabel(Account.Industry).mockId('mockingQuery').toList();

		// Verify
		for (Account mockedResult : result) {
			Assert.isTrue(mockedResult.isSet(Account.Name), 'When toLabel presented all mocked fields should be returned as they are.');
			Assert.isTrue(mockedResult.isSet(Account.Description), 'When toLabel presented all mocked fields should be returned as they are.');
			Assert.isTrue(mockedResult.isSet(Account.Website), 'When toLabel presented all mocked fields should be returned as they are.');
			Assert.isFalse(mockedResult.isSet(Account.Industry), 'When toLabel presented all mocked fields should be returned as they are.');
		}
	}

	@IsTest
	static void mockWithManyFieldAndAliasing() {
		// Setup
		List<Account> accounts = new List<Account>{
			new Account(Name = 'Test 1', Description = 'Test 1 Description', Website = 'www.beyondthecloud.dev'),
			new Account(Name = 'Test 2', Description = 'Test 2 Description', Website = 'www.beyondthecloud.dev')
		};

		QueryException soqlException = null;

		// Test
		rflib_SOQL.mock('mockingQuery').thenReturn(accounts);

		try {
			rflib_SOQL.of(Account.SObjectType).with(Account.Name).with(Account.Industry, 'accIndustry').mockId('mockingQuery').toList();
		} catch (QueryException e) {
			soqlException = e;
		}

		// Verify
		Assert.isNotNull(soqlException, 'Query mocking exception should be thrown.');
		Assert.areEqual('Use toAggregatedProxy() to mock AggregateResult records.', soqlException.getMessage(), 'Mocking field aliasing is not supported');
	}

	@IsTest
	static void mockWithManyFieldAndAggregateFunction() {
		// Setup
		List<Account> accounts = new List<Account>{
			new Account(Name = 'Test 1', Description = 'Test 1 Description', Website = 'www.beyondthecloud.dev'),
			new Account(Name = 'Test 2', Description = 'Test 2 Description', Website = 'www.beyondthecloud.dev')
		};

		QueryException soqlException = null;

		// Test
		rflib_SOQL.mock('mockingQuery').thenReturn(accounts);

		try {
			rflib_SOQL.of(Account.SObjectType).count(Account.Industry).mockId('mockingQuery').toAggregated();
		} catch (QueryException e) {
			soqlException = e;
		}

		// Verify
		Assert.isNotNull(soqlException, 'Query mocking exception should be thrown.');
		Assert.areEqual('Use toAggregatedProxy() to mock AggregateResult records.', soqlException.getMessage(), 'Mocking field aliasing is not supported');
	}

	@IsTest
	static void mockWithManyFieldAndParentRelationship() {
		// Setup
		List<Account> accounts = new List<Account>{
			new Account(Name = 'Test 1', Description = 'Test 1 Description', Website = 'www.beyondthecloud.dev', Parent = new Account(Name = 'Parent 1')),
			new Account(Name = 'Test 2', Description = 'Test 2 Description', Website = 'www.beyondthecloud.dev', Parent = new Account(Name = 'Parent 2'))
		};

		// Test
		rflib_SOQL.mock('mockingQuery').thenReturn(accounts);
		List<Account> result = rflib_SOQL.of(Account.SObjectType).with(Account.Name, Account.Industry).with('Parent', Account.Name).mockId('mockingQuery').toList();

		// Verify
		Assert.areEqual(accounts.size(), result.size(), 'The result accounts size should be the same size of mocked accounts.');

		for (Account mockedResult : result) {
			Assert.isNotNull(mockedResult.Name, 'Account Name should be set.');
			Assert.isNotNull(mockedResult.Description, 'The Account Description should be set.');
			Assert.isNotNull(mockedResult.Website, 'The Account Website should be set.');
			Assert.isNotNull(mockedResult.Parent.Name, 'The Parent Account should be set.');
			Assert.isFalse(mockedResult.isSet(Account.Industry), 'Account Industry should be not set, because it\'s not mocked.');
		}
	}

	@IsTest
	static void mockWithAggregateResultProxy() {
		// Setup
		Map<String, Object> aggregateResult = new Map<String, Object>{ 'LeadSource' => 'Web',  'total' => 10};

		// Test
		rflib_SOQL.mock('mockingQuery').thenReturn(aggregateResult);

		List<rflib_SOQL.AggregateResultProxy> results = rflib_SOQL.of(Lead.SObjectType)
			.with(Lead.LeadSource)
			.count(Lead.Id, 'total')
			.groupBy(Lead.LeadSource)
			.mockId('mockingQuery')
			.toAggregatedProxy();

		// Verify
		Assert.areEqual(1, results.size(), 'The size of the aggregate results should match the mocked size.');

		rflib_SOQL.AggregateResultProxy result = results[0];

		Assert.isNotNull(result.getPopulatedFieldsAsMap(), 'AggregateResult should contain populated fields.');
		Assert.areEqual(10, result.get('total'), 'AggregateResult should contain the total field.');
		Assert.areEqual('Web', result.get('LeadSource'), 'AggregateResult should contain the LeadSource field.');
	}

	@IsTest
	static void mockWithAggregateResultsProxy() {
		// Setup
		List<Map<String, Object>> aggregateResults = new List<Map<String, Object>>{
			new Map<String, Object>{ 'LeadSource' => 'Web',  'total' => 10},
			new Map<String, Object>{ 'LeadSource' => 'Phone', 'total' => 5},
			new Map<String, Object>{ 'LeadSource' => 'Email', 'total' => 3}
		};

		// Test
		rflib_SOQL.mock('mockingQuery').thenReturn(aggregateResults);

		List<rflib_SOQL.AggregateResultProxy> result = rflib_SOQL.of(Lead.SObjectType)
			.with(Lead.LeadSource)
			.count(Lead.Id, 'total')
			.groupBy(Lead.LeadSource)
			.mockId('mockingQuery')
			.toAggregatedProxy();

		// Verify
		Assert.areEqual(3, result.size(), 'The size of the aggregate results should match the mocked size.');

		for (rflib_SOQL.AggregateResultProxy aggregateResult : result) {
			Assert.isNotNull(aggregateResult.getPopulatedFieldsAsMap(), 'AggregateResult should contain populated fields.');
			Assert.isNotNull(aggregateResult.get('total'), 'AggregateResult should contain the total field.');
			Assert.isNotNull(aggregateResult.get('LeadSource'), 'AggregateResult should contain the LeadSource field.');
		}
	}

	@IsTest
	static void mockSubQuery() {
		// Setup
		List<Account> mocks = (List<Account>) JSON.deserialize(
			JSON.serialize(
				new List<Map<String, Object>>{
					new Map<String, Object>{
						'Name' => 'Account Name',
						'Industry' => 'IT',
						'Contacts' => new Map<String, Object>{
							'totalSize' => 2,
							'done' => true,
							'records' => new List<Map<String, Object>>{
								new Map<String, Object>{ 'Name' => 'Contact Name', 'Email' => 'contact.email@address.com', 'Phone' => '0987654321' },
								new Map<String, Object>{ 'Name' => 'Contact Name 2', 'Email' => 'contact2.email@address.com', 'Phone' => '1234567890' }
							}
						}
					}
				}
			),
			List<Account>.class
		);

		rflib_SOQL.mock('mockingQuery').thenReturn(mocks);

		// Test
		List<Account> result = rflib_SOQL.of(Account.SObjectType)
			.with(Account.Name, Account.Industry)
			.with(rflib_SOQL.SubQuery.of('Contacts')
				.with(Contact.Id, Contact.Name, Contact.Phone)
			)
			.mockId('mockingQuery')
			.toList();

		// Verify
		Assert.areEqual(1, result.size(), 'The size of the mocked accounts should match the expected one.');

		Account account = result[0];

		Assert.areEqual('Account Name', account.Name, 'The mocked account name should match the expected one.');
		Assert.areEqual('IT', account.Industry, 'The mocked account industry should match the expected one.');
		Assert.areEqual(2, account.Contacts.size(), 'The size of the mocked contacts should match the expected one.');

		Contact contact1 = (Contact) account.Contacts[0];

		Assert.areEqual('Contact Name', contact1.Name, 'The mocked contact name should match the expected one.');
		Assert.areEqual('contact.email@address.com', contact1.Email, 'The mocked contact email should match the expected one.');
		Assert.areEqual('0987654321', contact1.Phone, 'The mocked contact phone should match the expected one.');

		Contact contact2 = (Contact) account.Contacts[1];

		Assert.areEqual('Contact Name 2', contact2.Name, 'The mocked contact name should match the expected one.');
		Assert.areEqual('contact2.email@address.com', contact2.Email, 'The mocked contact email should match the expected one.');
		Assert.areEqual('1234567890', contact2.Phone, 'The mocked contact phone should match the expected one.');
	}

	@IsTest
	static void mockSubQueryWithStrippingAdditionalFields() {
		// Setup
		List<Account> mocks = (List<Account>) JSON.deserialize(
			JSON.serialize(
				new List<Map<String, Object>>{
					new Map<String, Object>{
						'Name' => 'Account Name',
						'Industry' => 'IT',
						'Contacts' => new Map<String, Object>{
							'totalSize' => 2,
							'done' => true,
							'records' => new List<Map<String, Object>>{
								new Map<String, Object>{ 'Name' => 'Contact Name', 'Email' => 'contact.email@address.com', 'Phone' => '0987654321' },
								new Map<String, Object>{ 'Name' => 'Contact Name 2', 'Email' => 'contact2.email@address.com', 'Phone' => '1234567890' }
							}
						},
						'Opportunities' => new Map<String, Object>{
							'totalSize' => 1,
							'done' => true,
							'records' => new List<Map<String, Object>>{
								new Map<String, Object>{ 'Name' => 'Opportunity Name', 'Amount' => 100000 }
							}
						}
					}
				}
			),
			List<Account>.class
		);

		rflib_SOQL.mock('mockingQuery').thenReturn(mocks);

		// Test
		List<Account> result = rflib_SOQL.of(Account.SObjectType)
			.with(Account.Name, Account.Industry)
			.with(rflib_SOQL.SubQuery.of('Contacts')
				.with(Contact.Id, Contact.Name, Contact.Phone)
			)
			.mockId('mockingQuery')
			.toList();

		// Verify
		Account account = result[0];

		Assert.areEqual(1, result.size(), 'The size of the mocked accounts should match the expected one.');
		Assert.areEqual(2, account.Contacts.size(), 'The size of the mocked opportunities should match the expected one.');
		Assert.areEqual(0, account.Opportunities.size(), 'The size of the mocked opportunities should be 0, because it was not requested.');
	}

	@IsTest
	static void sObjectsMockStack() {
		// Setup
		rflib_SOQL.mock('mockingQuery').thenReturn(new Account(Name = 'Test 1'));
		rflib_SOQL.mock('mockingQuery').thenReturn(new Account(Name = 'Test 2'));
		rflib_SOQL.mock('mockingQuery').thenReturn(new Account(Name = 'Test 3'));

		// Test
		rflib_SOQL.Queryable query = rflib_SOQL.of(Account.SObjectType).with(Account.Name).mockId('mockingQuery');

		Account acc1 = (Account) query.toObject();
		Account acc2 = (Account) query.toObject();
		Account acc3 = (Account) query.toObject();
		Account acc4 = (Account) query.toObject();

		// Verify
		Assert.areEqual('Test 1', acc1.Name, 'The returned account name should match the expected one.');
		Assert.areEqual('Test 2', acc2.Name, 'The returned account name should match the expected one.');
		Assert.areEqual('Test 3', acc3.Name, 'The returned account name should match the expected one.');
		Assert.areEqual('Test 3', acc4.Name, 'The returned account name should match the expected one.');
	}

	@IsTest
	static void countMockStack() {
		// Setup
		rflib_SOQL.mock('mockingQuery').thenReturn(1);
		rflib_SOQL.mock('mockingQuery').thenReturn(2);
		rflib_SOQL.mock('mockingQuery').thenReturn(3);

		// Test
		Integer result1 = rflib_SOQL.of(Account.SObjectType).mockId('mockingQuery').count().toInteger();
		Integer result2 = rflib_SOQL.of(Account.SObjectType).mockId('mockingQuery').count().toInteger();
		Integer result3 = rflib_SOQL.of(Account.SObjectType).mockId('mockingQuery').count().toInteger();
		Integer result4 = rflib_SOQL.of(Account.SObjectType).mockId('mockingQuery').count().toInteger();

		// Verify
		Assert.areEqual(1, result1, 'The returned count should match the expected one.');
		Assert.areEqual(2, result2, 'The returned count should match the expected one.');
		Assert.areEqual(3, result3, 'The returned count should match the expected one.');
		Assert.areEqual(3, result4, 'The returned count should match the expected one.');
	}

	@IsTest
	static void aggregatedMockStack() {
		// Setup
		rflib_SOQL.mock('mockingQuery').thenReturn(new Map<String, Object>{ 'LeadSource' => 'Web',  'total' => 10});
		rflib_SOQL.mock('mockingQuery').thenReturn(new Map<String, Object>{ 'LeadSource' => 'Phone', 'total' => 5});
		rflib_SOQL.mock('mockingQuery').thenReturn(new Map<String, Object>{ 'LeadSource' => 'Email', 'total' => 3});

		// Test
		List<rflib_SOQL.AggregateResultProxy> result1 = rflib_SOQL.of(Lead.SObjectType)
			.with(Lead.LeadSource)
			.count(Lead.Id, 'total')
			.groupBy(Lead.LeadSource)
			.mockId('mockingQuery')
			.toAggregatedProxy();

		List<rflib_SOQL.AggregateResultProxy> result2 = rflib_SOQL.of(Lead.SObjectType)
			.with(Lead.LeadSource)
			.count(Lead.Id, 'total')
			.groupBy(Lead.LeadSource)
			.mockId('mockingQuery')
			.toAggregatedProxy();

		List<rflib_SOQL.AggregateResultProxy> result3 = rflib_SOQL.of(Lead.SObjectType)
			.with(Lead.LeadSource)
			.count(Lead.Id, 'total')
			.groupBy(Lead.LeadSource)
			.mockId('mockingQuery')
			.toAggregatedProxy();

		List<rflib_SOQL.AggregateResultProxy> result4 = rflib_SOQL.of(Lead.SObjectType)
			.with(Lead.LeadSource)
			.count(Lead.Id, 'total')
			.groupBy(Lead.LeadSource)
			.mockId('mockingQuery')
			.toAggregatedProxy();

		// Verify
		Assert.areEqual(1, result1.size(), 'The size of the aggregate results should match the mocked size.');
		Assert.areEqual(10, result1[0].get('total'), 'The total should match the expected one.');
		Assert.areEqual('Web', result1[0].get('LeadSource'), 'The LeadSource should match the expected one.');

		Assert.areEqual(1, result2.size(), 'The size of the aggregate results should match the mocked size.');
		Assert.areEqual(5, result2[0].get('total'), 'The total should match the expected one.');
		Assert.areEqual('Phone', result2[0].get('LeadSource'), 'The LeadSource should match the expected one.');

		Assert.areEqual(1, result3.size(), 'The size of the aggregate results should match the mocked size.');
		Assert.areEqual(3, result3[0].get('total'), 'The total should match the expected one.');
		Assert.areEqual('Email', result3[0].get('LeadSource'), 'The LeadSource should match the expected one.');

		Assert.areEqual(1, result4.size(), 'The size of the aggregate results should match the mocked size.');
		Assert.areEqual(3, result4[0].get('total'), 'The total should match the expected one.');
		Assert.areEqual('Email', result4[0].get('LeadSource'), 'The LeadSource should match the expected one.');
	}

	@IsTest
	static void toId() {
		// Setup
		Account acc = new Account(Name = 'Test 1');
		insert acc;

		// Test
		Id accountId = rflib_SOQL.of(Account.SObjectType).byId(acc).toId();

		// Verify
		Assert.areEqual(acc.Id, accountId, 'The returned Id should match the expected one.');
	}

	@IsTest
	static void toIdWithMocking() {
		// Setup
		rflib_SOQL.mock('mockingQuery').thenReturn(new Account(Name = 'Test 1'));

		// Test
		Id accountId = rflib_SOQL.of(Account.SObjectType).mockId('mockingQuery').toId();

		// Verify
		Assert.isNotNull(accountId, 'The returned Id should match the expected one.');
	}

	@IsTest
	static void toIds() {
		// Setup
		List<Account> accounts = insertAccounts();

		// Test
		Set<Id> accountIds = rflib_SOQL.of(Account.SObjectType).byIds(accounts).toIds();

		// Verify
		Assert.areEqual(accounts.size(), accountIds.size(), 'The size of the returned set should be equal to the size of the inserted accounts.');
	}

	@IsTest
	static void toIdsWithMocking() {
		// Setup
		rflib_SOQL.mock('mockingQuery').thenReturn(new List<SObject>{
			new Account(Name = 'Test 1'),
			new Account(Name = 'Test 2')
		});

		// Test
		Set<Id> accountIds = rflib_SOQL.of(Account.SObjectType).mockId('mockingQuery').toIds();

		// Verify
		Assert.areEqual(2, accountIds.size(), 'The size of the returned set should be equal to the size of the mocked accounts.');
	}

	@IsTest
	static void toIdsOf() {
		// Setup
		List<Account> accounts = insertAccountsWithParents();

		// Test
		Set<Id> parentIds = rflib_SOQL.of(Account.SObjectType).byIds(accounts).toIdsOf(Account.ParentId);

		// Verify
		Assert.areEqual(accounts.size(), parentIds.size(), 'The size of the returned set should be equal to the size of the inserted accounts.');
	}

	@IsTest
	static void toIdsOfWhenCustomConditions() {
		// Setup
		List<Account> accounts = insertAccountsWithParents();

		// Test
		Set<Id> parentIds = rflib_SOQL.of(Account.SObjectType)
			.byIds(accounts)
			.whereAre(rflib_SOQL.Filter.with(Account.Name).contains('Test 1'))
			.whereAre(rflib_SOQL.Filter.with(Account.Name).equal('Test 1'))
			.conditionLogic('1 AND (2 OR 3)')
			.toIdsOf(Account.ParentId);

		// Verify
		Assert.areEqual(1, parentIds.size(), 'Only one account should be returned, because the Name condition is matched.');
	}

	@IsTest
	static void toIdsOfWhenAnyConditionMatching() {
		// Setup
		List<Account> accounts = insertAccountsWithParents();

		// Test
		Set<Id> parentIds = rflib_SOQL.of(Account.SObjectType)
			.byIds(accounts)
			.whereAre(rflib_SOQL.Filter.with(Account.Name).equal('Test 1'))
			.anyConditionMatching()
			.toIdsOf(Account.ParentId);

		// Verify
		Assert.areEqual(2, parentIds.size(), 'Only one account should be returned, because the Name condition is matched.');
	}

	@IsTest
	static void toIdsOfWithMocking() {
		// Setup
		Id parentId1 = rflib_SOQL.IdGenerator.get(Account.SObjectType);
		Id parentId2 = rflib_SOQL.IdGenerator.get(Account.SObjectType);

		rflib_SOQL.mock('mockingQuery').thenReturn(new List<Account>{
			new Account(ParentId = parentId1),
			new Account(ParentId = parentId2)
		});

		// Test
		Set<Id> parentIds = rflib_SOQL.of(Account.SObjectType).mockId('mockingQuery').toIdsOf(Account.ParentId);

		// Verify
		Assert.areEqual(2, parentIds.size(), 'The size of the returned set should be equal to the size of the mocked accounts.');
		Assert.isTrue(parentIds.contains(parentId1), 'The returned set should contain the parent Id 1.');
		Assert.isTrue(parentIds.contains(parentId2), 'The returned set should contain the parent Id 2.');
	}

	@IsTest
	static void toIdsOfWithMockingStack() {
		// Setup
		Id parentId1 = rflib_SOQL.IdGenerator.get(Account.SObjectType);
		Id parentId2 = rflib_SOQL.IdGenerator.get(Account.SObjectType);

		rflib_SOQL.mock('mockingQuery').thenReturn(new List<Account>{
			new Account(ParentId = parentId1),
			new Account(ParentId = parentId2)
		});

		rflib_SOQL.mock('mockingQuery').thenReturn(new List<Account>{
			new Account(ParentId = parentId1)
		});

		// Test
		Set<Id> parentIds1 = rflib_SOQL.of(Account.SObjectType).mockId('mockingQuery').toIdsOf(Account.ParentId);
		Set<Id> parentIds2 = rflib_SOQL.of(Account.SObjectType).mockId('mockingQuery').toIdsOf(Account.ParentId);

		// Verify
		Assert.areEqual(2, parentIds1.size(), 'The size of the returned set should be equal to the size of the mocked accounts.');
		Assert.isTrue(parentIds1.contains(parentId1), 'The returned set should contain the parent Id 1.');
		Assert.isTrue(parentIds1.contains(parentId2), 'The returned set should contain the parent Id 2.');

		Assert.areEqual(1, parentIds2.size(), 'The size of the returned set should be equal to the size of the mocked accounts.');
		Assert.isTrue(parentIds2.contains(parentId1), 'The returned set should contain the parent Id 1.');
	}
	
	@IsTest
	static void toIdsOfRelationshipField() {
		// Setup
		List<Account> accounts = insertAccountsWithParents();

		// Test
		Set<Id> createdByIds = rflib_SOQL.of(Account.SObjectType).byIds(accounts).toIdsOf('Parent', Account.CreatedById);

		// Verify
		Assert.areEqual(1, createdByIds.size(), 'The size of the returned set should be 1, because the same user inserted the accounts.');
	}

	@IsTest
	static void toIdsOfRelationshipFieldWithMocking() {
		// Setup
		Id parentAccountId = rflib_SOQL.IdGenerator.get(Account.SObjectType);

		rflib_SOQL.mock('mockingQuery').thenReturn(
			new Account(Parent = new Account(Id = parentAccountId))
		);

		// Test
		Set<Id> parentIds = rflib_SOQL.of(Account.SObjectType).mockId('mockingQuery').toIdsOf('Parent', Account.Id);

		// Verify
		Assert.areEqual(1, parentIds.size(), 'The size of the returned set should be 1, because the same user inserted the accounts.');
		Assert.isTrue(parentIds.contains(parentAccountId), 'The returned set should contain the parent account Id.');
	}

	@IsTest
	static void doExist() {
		// Setup
		Account acc = new Account(Name = 'Test 1');
		insert acc;

		// Test
		Boolean isRecordExist = rflib_SOQL.of(Account.SObjectType).byId(acc).doExist();

		// Verify
		Assert.isTrue(isRecordExist, 'The record with given Id should exist.');
	}

	@IsTest
	static void multipleToStringExecutions() {
		// Setup
		Exception soqlException = null;

		rflib_SOQL.Queryable builder = rflib_SOQL.of(Account.SObjectType)
			.whereAre(rflib_SOQL.FilterGroup
				.add(rflib_SOQL.Filter.with(Account.Name).equal('Test'))
				.add(rflib_SOQL.Filter.with(Account.Industry).equal('IT'))
			);

		// Test
		try {
			builder.preview();
			builder.toString();
			builder.toString();
			builder.toList();
		} catch (Exception e) {
			soqlException = e;
		}

		// Verify
		Assert.isNull(soqlException, 'The rflib_SOQL should be generated without any exceptions.');

		Assert.areEqual('SELECT Id FROM Account WHERE (Name = :v1 AND Industry = :v2)', builder.toString(), 'The generated rflib_SOQL should match the expected one.');

		Map<String, Object> binding = builder.binding();
		Assert.areEqual('Test', binding.get('v1'), 'The binding variable should match the expected value.');
		Assert.areEqual('IT', binding.get('v2'), 'The binding variable should match the expected value.');
	}

	@IsTest
	static void toValueOf() {
		// Setup
		String accountName = 'Test 1';

		Account acc = new Account(Name = accountName);
		insert acc;

		// Test
		String resultAccName = (String) rflib_SOQL.of(Account.SObjectType).byId(acc).toValueOf(Account.Name);

		// Verify
		Assert.areEqual(accountName, resultAccName, 'The returned account name should match the expected one.');
	}

	@IsTest
	static void mockedToValueOf() {
		// Setup
		String accountName = 'Test 1';

		// Test
		rflib_SOQL.mock('mockingQuery').thenReturn(new Account(Name = accountName));
		String resultAccName = (String) rflib_SOQL.of(Account.SObjectType).mockId('mockingQuery').toValueOf(Account.Name);

		// Verify
		Assert.areEqual(accountName, resultAccName, 'The returned account name should match the expected one.');
	}

	@IsTest
	static void toValuesOf() {
		// Setup
		List<Account> accounts = insertAccounts();

		// Test
		Set<String> accountNames = rflib_SOQL.of(Account.SObjectType).byIds(accounts).toValuesOf(Account.Name);

		// Verify
		Assert.areEqual(2, accountNames.size(), 'The size of the account names set should be equal to the size of the accounts.');
	}

	@IsTest
	static void toValuesOfWhenCustomConditions() {
		// Setup
		List<Account> accounts = insertAccounts();

		// Test
		Set<String> accountNames = rflib_SOQL.of(Account.SObjectType)
			.byIds(accounts)
			.whereAre(rflib_SOQL.Filter.with(Account.Name).contains('Test 1'))
			.whereAre(rflib_SOQL.Filter.with(Account.Name).equal('Test 1'))
			.conditionLogic('1 AND (2 OR 3)')
			.toValuesOf(Account.Name);

		// Verify
		Assert.areEqual(1, accountNames.size(), 'Only one account should be returned, because the Name condition is matched.');
	}

	@IsTest
	static void toValuesOfWhenNoValues() {
		// Setup
		insertAccounts(); // Industry is empty

		// Test
		Set<String> accountsIndustries = rflib_SOQL.of(Account.SObjectType).toValuesOf(Account.Industry);

		// Verify
		Assert.areEqual(0, accountsIndustries.size(), 'The size of the account industries set should be 0, because field is empty.');
	}

	@IsTest
	static void toValuesOfWithDefaultFields() {
		// Setup
		List<Account> accounts = insertAccounts();

		// Test
		Set<String> accountNames = rflib_SOQL.of(Account.SObjectType)
			.with(Account.Industry)
			.byIds(accounts)
			.toValuesOf(Account.Name);

		// Verify
		Assert.areEqual(2, accountNames.size(), 'The size of the account names set should be equal to the size of the accounts.');
	}

	@IsTest
	static void toValueOfWhenRecordNotExist() {
		// Test
		String accountIndustry = (String) rflib_SOQL.of(Account.SObjectType)
			.whereAre(rflib_SOQL.Filter.name().equal('Test'))
			.toValueOf(Account.Industry);

		// Verify
		Assert.isNull(accountIndustry, 'The account industry should be null, because the record does not exist.');
	}

	@IsTest
	static void toValuesOfRelationshipField() {
		// Setup
		List<Account> accounts = insertAccountsWithParents();

		// Test
		Set<String> accountNames = rflib_SOQL.of(Account.SObjectType)
			.byIds(accounts)
			.toValuesOf('Parent', Account.Name);

		// Verify
		Assert.areEqual(2, accountNames.size(), 'Each account should have a parent, so the size of the account names set should be equal to the size of the accounts.');
	}

	@IsTest
	static void toValuesOfRelationshipFieldWhenRelatedRecordNotExist() {
		// Test
		Set<String> accountNames = rflib_SOQL.of(Account.SObjectType)
			.whereAre(rflib_SOQL.Filter.name().equal('Test'))
			.toValuesOf('Parent', Account.Name);

		// Verify
		Assert.isTrue(accountNames.isEmpty(), 'The account names set should be empty, because the related record does not exist.');
	}

	@IsTest
	static void toObject() {
		// Setup
		Account acc = new Account(Name = 'Test 1');
		insert acc;

		// Test
		Account result = (Account) rflib_SOQL.of(Account.SObjectType).toObject();

		// Verify
		Assert.areEqual(acc.Id, result.Id, 'The returned account should match the expected one.');
	}

	@IsTest
	static void toObjectWithMultipleRows() {
		// Setup
		insertAccounts();
		Exception queryException = null;

		// Test
		try {
			rflib_SOQL.of(Account.SObjectType).toObject();
		} catch (Exception e) {
			queryException = e; // List has more than 1 row for assignment to SObject
		}

		// Verify
		Assert.isNotNull(queryException, 'The exception should be thrown, because there are more than 1 row for assignment to SObject.');
	}

	@IsTest
	static void toObjectWithoutRows() {
		// Test
		// When List has no rows for assignment to SObject null will be returned
		Account account = (Account) rflib_SOQL.of(Account.SObjectType).toObject();

		// Verify
		Assert.isNull(account, 'The account should be null, because there are no rows for assignment to SObject.');
	}

	@IsTest
	static void toList() {
		// Setup
		List<Account> accounts = insertAccounts();

		// Test
		List<Account> result = rflib_SOQL.of(Account.SObjectType).toList();

		// Verify
		Assert.areEqual(accounts.size(), result.size(), 'The size of the result list should be equal to the size of the inserted accounts.');
	}

	@IsTest
	static void toAggregated() {
		// Setup
		List<Account> accounts = insertAccounts();

		// Test
		List<AggregateResult> result = rflib_SOQL.of(Account.SObjectType).count(Account.Name, 'names').toAggregated();

		// Verify
		Assert.areEqual(accounts.size(), result[0].get('names'), 'The count of the names should be equal to the size of the inserted accounts.');
	}

	@IsTest
	static void toIntegerWithoutSpecifiedCount() {
		// Setup
		List<Account> accounts = insertAccounts();

		// Test
		Integer accountsCount = rflib_SOQL.of(Account.SObjectType).toInteger();

		// Verify
		Assert.areEqual(accounts.size(), accountsCount, 'The COUNT() clause should be automatically added when the count() method is not specified. The count of the accounts should match the number of inserted accounts.');
	}

	@IsTest
	static void toInteger() {
		// Setup
		List<Account> accounts = insertAccounts();

		// Test
		Integer result = rflib_SOQL.of(Account.SObjectType).count().toInteger();

		// Verify
		Assert.areEqual(accounts.size(), result, 'The count of the accounts should match the number of inserted accounts.');
	}

	@IsTest
	static void toMap() {
		// Setup
		List<Account> accounts = insertAccounts();

		// Test
		Map<Id, Account> result = (Map<Id, Account>) rflib_SOQL.of(Account.SObjectType).toMap();

		// Verify
		Assert.areEqual(accounts.size(), result.size(), 'Size of the result map should be equal to the size of the inserted accounts.');

		for (Account acc : accounts) {
			Assert.isNotNull(result.get(acc.Id), 'The result map should have a value for each inserted account Id.');
		}
	}

	@IsTest
	static void mockedToMapWithoutMockedId() {
		// Setup
		List<Account> accounts = new List<Account>{
			new Account(Name = 'Test 1'),
			new Account(Name = 'Test 2')
		};

		// Test
		rflib_SOQL.mock('mockingQuery').thenReturn(accounts);
		Map<Id, Account> result = (Map<Id, Account>) rflib_SOQL.of(Account.SObjectType).mockId('mockingQuery').toMap();

		// Verify
		Assert.areEqual(accounts.size(), result.size(), 'Size of the result map should be equal to the size of the inserted accounts.');
		Assert.areEqual(accounts.size(), result.keySet().size(), 'Size of the result map should be equal to the size of the inserted accounts.');
	}

	@IsTest
	static void toMapWithMockingWhenOtherFieldsAreSpecified() {
		// Setup
		List<Account> accounts = new List<Account>{
			new Account(Id = rflib_SOQL.IdGenerator.get(Account.SObjectType), Name = 'Test 1', Description = 'Test 1 Description', Website = 'www.beyondthecloud.dev'),
			new Account(Id = rflib_SOQL.IdGenerator.get(Account.SObjectType), Name = 'Test 2', Description = 'Test 2 Description', Website = 'www.beyondthecloud.dev')
		};

		// Test
		rflib_SOQL.mock('mockingQuery').thenReturn(accounts);

		Map<Id, Account> result = (Map<Id, Account>) rflib_SOQL.of(Account.SObjectType)
			.with(Account.Name, Account.Description)
			.mockId('mockingQuery')
			.toMap();

		// Verify
		Assert.areEqual(accounts.size(), result.size(), 'Size of the result map should be equal to the size of the inserted accounts.');

		for (Account acc : accounts) {
			Assert.isNotNull(result.get(acc.Id), 'The result map should have a value for each inserted account Id.');
			Assert.isNotNull(result.get(acc.Id).Name, 'The result map should have a value for each inserted account Name.');
			Assert.isNotNull(result.get(acc.Id).Description, 'The result map should have a value for each inserted account Description.');
			Assert.isNull(result.get(acc.Id).Website, 'The result map should not have a value for each inserted account Website.');
		}
	}

	@IsTest
	static void toIdMapBy() {
		// Setup
		insertAccountsWithParents();

		// Test
		Map<Id, Account> result = (Map<Id, Account>) rflib_SOQL.of(Account.SObjectType).with(Account.Id, Account.Name).toIdMapBy(Account.ParentId);

		// Verify
		Assert.areEqual(2, result.size(), 'Size of the result map should be equal to the size of the inserted accounts with parents.');
	}

	@IsTest
	static void mockedToIdMapBy() {
		// Setup
		rflib_SOQL.mock('mockingQuery').thenReturn(new List<Account>{
			new Account(Name = 'Account 1', ParentId = rflib_SOQL.IdGenerator.get(Account.SObjectType)),
			new Account(Name = 'Account 2', ParentId = rflib_SOQL.IdGenerator.get(Account.SObjectType))
		});

		// Test
		Map<Id, Account> result = (Map<Id, Account>) rflib_SOQL.of(Account.SObjectType)
			.with(Account.Id, Account.Name).mockId('mockingQuery')
			.toIdMapBy(Account.ParentId);

		// Verify
		Assert.areEqual(2, result.size(), 'Size of the result map should be equal to the size of the inserted accounts with parents.');
	}

	@IsTest
	static void toIdMapByRelationshipField() {
		// Setup
		insertAccountsWithParents();

		// Test
		Map<Id, Account> result = (Map<Id, Account>) rflib_SOQL.of(Account.SObjectType).toIdMapBy('Parent', Account.CreatedById);

		// Verify
		Assert.areEqual(1, result.size(), 'Size of the result map should be equal to 1, because the accounts have the same created by user.');
		Assert.isTrue(result.containsKey(UserInfo.getUserId()), 'The result map should have a key: UserInfo.getUserId().');
	}

	@IsTest
	static void mockedToIdMapByRelationshipField() {
		// Setup
		rflib_SOQL.mock('mockingQuery').thenReturn(new List<Account>{
			new Account(Name = 'Account 1', Parent = new Account(Name = 'Parent 1', Id = rflib_SOQL.IdGenerator.get(Account.SObjectType))),
			new Account(Name = 'Account 2', Parent = new Account(Name = 'Parent 2', Id = rflib_SOQL.IdGenerator.get(Account.SObjectType)))
		});

		// Test
		Map<Id, Account> result = (Map<Id, Account>) rflib_SOQL.of(Account.SObjectType).mockId('mockingQuery').toIdMapBy('Parent', Account.Id);

		// Verify
		Assert.areEqual(2, result.size(), 'Size of the result map should be equal to 2, because the accounts have 2 different parents.');
	}

	@IsTest
	static void toAggregatedIdMapBy() {
		// Setup
		insertAccountsWithParents();

		// Test
		Map<Id, List<Account>> result = (Map<Id, List<Account>>) rflib_SOQL.of(Account.SObjectType).toAggregatedIdMapBy(Account.ParentId);

		// Verify
		Assert.areEqual(2, result.size(), 'Size of the result map should be equal to 2, because the accounts have 2 parents.');
	}

	@IsTest
	static void mockedtoAggregatedIdMapBy() {
		// Setup
		Id parentId = rflib_SOQL.IdGenerator.get(Account.SObjectType);

		rflib_SOQL.mock('mockingQuery').thenReturn(new List<Account>{
			new Account(Name = 'Account 1', ParentId = parentId),
			new Account(Name = 'Account 2', ParentId = parentId)
		});

		// Test
		Map<Id, List<Account>> result = (Map<Id, List<Account>>) rflib_SOQL.of(Account.SObjectType).mockId('mockingQuery').toAggregatedIdMapBy(Account.ParentId);

		// Verify
		Assert.areEqual(1, result.size(), 'Size of the result map should be equal to 1, because the accounts have common parent.');
	}

	@IsTest
	static void toAggregatedIdMapByRelationshipField() {
		// Setup
		insertAccountsWithParents();

		// Test
		Map<Id, List<Account>> result = (Map<Id, List<Account>>) rflib_SOQL.of(Account.SObjectType).mockId('mockingQuery').toAggregatedIdMapBy('Parent', Account.CreatedById);

		// Verify
		Assert.areEqual(1, result.size(), 'Size of the result map should be equal to 1, because the same user created all accounts.');
	}

	@IsTest
	static void mockedtoAggregatedIdMapByRelationshipField() {
		// Setup
		Id parentId = rflib_SOQL.IdGenerator.get(Account.SObjectType);

		rflib_SOQL.mock('mockingQuery').thenReturn(new List<Account>{
			new Account(Name = 'Account 1', Parent = new Account(Name = 'Parent 1', Id = parentId)),
			new Account(Name = 'Account 2', Parent = new Account(Name = 'Parent 2', Id = parentId))
		});

		// Test
		Map<Id, List<Account>> result = (Map<Id, List<Account>>) rflib_SOQL.of(Account.SObjectType).mockId('mockingQuery').toAggregatedIdMapBy('Parent', Account.Id);

		// Verify
		Assert.areEqual(1, result.size(), 'Size of the result map should be equal to 1, because all parent accounts have the same parent.');
	}

	@IsTest
	static void toMapWithCustomKey() {
		// Setup
		List<Account> accounts = insertAccounts();

		// Test
		Map<String, Account> result = (Map<String, Account>) rflib_SOQL.of(Account.SObjectType).toMap(Account.Name);

		// Verify
		Assert.areEqual(accounts.size(), result.size(), 'Size of the result map should be equal to the size of the inserted accounts.');

		for (Account acc : accounts) {
			Assert.isNotNull(result.get(acc.Name), 'The result map should have a value for each inserted account Name.');
		}
	}

	@IsTest
	static void toMapWithCustomRelationshipKey() {
		// Setup
		List<Account> accounts = insertAccountsWithParents();

		// Test
		Map<String, Account> result = (Map<String, Account>) rflib_SOQL.of(Account.SObjectType)
			.whereAre(rflib_SOQL.Filter.with(Account.ParentId).isNotNull())
			.toMap('Parent', Account.Name);

		// Verify
		Assert.areEqual(accounts.size(), result.size(), 'Size of the result map should be equal to the size of the accounts with parents.');
		Assert.isNotNull(result.get('Test 1 Parent'), 'The result map should have a value for the key: "Test 1 Parent".');
		Assert.isNotNull(result.get('Test 2 Parent'), 'The result map should have a value for the key: "Test 2 Parent".');
	}

	@IsTest
	static void toMapWithEmptyCustomRelationshipKey() {
		// Setup
		insertAccountsWithParents();

		// Test
		Map<String, Account> result = (Map<String, Account>) rflib_SOQL.of(Account.SObjectType).toMap('Parent', Account.Name);

		// Verify
		Assert.areEqual(2, result.size(), 'Size of the result map should be equal to 2, because there are two accounts with different parents.');
	}

	@IsTest
	static void toMapWithCustomKeyAndCustomValue() {
		// Setup
		List<Account> accounts = insertAccounts();

		// Test
		Map<String, String> result = rflib_SOQL.of(Account.SObjectType).toMap(Account.Name, Account.Id);

		// Verify
		Assert.areEqual(accounts.size(), result.size(), 'Size of the result map should be equal to the size of the inserted accounts.');

		for (Account acc : accounts) {
			Assert.isNotNull(result.get(acc.Name), 'The result map should have a value for each inserted account Name.');
			Assert.areEqual(acc.Id, result.get(acc.Name), 'The result map should have an account Id for each account Name.');
		}
	}

	@IsTest
	static void toAggregatedMapWithCustomKey() {
		// Setup
		List<Account> accounts = insertAccounts();

		// Test
		Map<String, List<Account>> result = rflib_SOQL.of(Account.SObjectType).toAggregatedMap(Account.Name);

		// Verify
		Assert.areEqual(accounts.size(), result.size(), 'Size of the result map should be equal to the size of the inserted accounts.');

		for (Account acc : accounts) {
			Assert.isFalse(result.get(acc.Name).isEmpty(), 'The result map should contain a non-empty account list for each account name.');
		}
	}

	@IsTest
	static void toAggregatedMapWithCustomRelationshipKey() {
		// Setup
		List<Account> accounts = insertAccountsWithParents();

		// Test
		Map<String, List<Account>> result = rflib_SOQL.of(Account.SObjectType)
			.whereAre(rflib_SOQL.Filter.with(Account.ParentId).isNotNull())
			.toAggregatedMap('Parent.CreatedBy', User.Id);

		// Verify
		Assert.areEqual(1, result.size(), 'Size of the result map should be 1, because the same user created all accounts.');
		Assert.areEqual(accounts.size(), result.get(UserInfo.getUserId()).size(), 'The result map should contain all accounts created by the current User.');
	}

	@IsTest
	static void toAggregatedMapWithEmptyCustomKey() {
		// Setup
		insertAccounts();

		// Test
		Map<String, List<Account>> result = rflib_SOQL.of(Account.SObjectType).toAggregatedMap(Account.Name);

		// Verify
		Assert.areEqual(2, result.size(), 'The result map should have only two keys, because there are two accounts with different names.');
	}

	@IsTest
	static void toAggregatedMapWithCustomKeyAndCustomValue() {
		// Setup
		List<Account> accounts = insertAccounts();

		// Test
		Map<String, List<String>> result = rflib_SOQL.of(Account.SObjectType).toAggregatedMap(Account.Name, Account.Id);

		// Verify
		Assert.areEqual(accounts.size(), result.size(), 'Size of the result map should be equal to the size of the inserted accounts.');

		for (Account acc : accounts) {
			Assert.isFalse(result.get(acc.Name).isEmpty(), 'The result map should contain a non-empty list of account Ids for each account name.');
		}
	}

	@IsTest
	static void toAggregatedMapWithEmptyCustomKeyAndCustomValue() {
		// Setup
		insertAccounts();

		// Test
		Map<String, List<String>> result = rflib_SOQL.of(Account.SObjectType).toAggregatedMap(Account.Name, Account.Id);

		// Verify
		Assert.areEqual(2, result.size(), 'The result map should have only two keys, because there are two accounts with different names.');
	}

	@IsTest
	static void toAggregatedMapWithCustomKeyAndCustomRelationshipValue() {
		// Setup
		insertAccountsWithParents();

		// Test
		Map<String, List<String>> result = rflib_SOQL.of(Account.SObjectType).toAggregatedMap(Account.Name, 'Parent', Account.Id);

		// Verify
		Assert.areEqual(4, result.size(), 'The result map should have 4 keys for each account name.');
	}

	@IsTest
	static void toQueryLocator() {
		// Test
		Database.QueryLocator queryLocator = rflib_SOQL.of(Account.SObjectType)
			.with(Account.Id)
			.with(Account.Name)
			.toQueryLocator();

		// Verify
		Assert.areEqual('SELECT Id, Name FROM Account', queryLocator.getQuery(), 'The generated rflib_SOQL should match the expected one.');
	}

	@IsTest
	static void toQueryLocatorWithSharing() {
		// Setup
		insertTasks();

		System.runAs(minimumAccessUser()) {
			// Test
			Database.QueryLocator queryLocator = rflib_SOQL.of(Task.SObjectType).systemMode().withSharing().toQueryLocator();

			// Verify
			Assert.isFalse(queryLocator.iterator().hasNext(), 'The user should not have access to the tasks, so hasNext should return false.');
		}
	}

	@IsTest
	static void toQueryLocatorWithoutSharing() {
		// Setup
		insertTasks();

		System.runAs(minimumAccessUser()) {
			// Test
			Database.QueryLocator queryLocator = rflib_SOQL.of(Task.SObjectType).systemMode().withoutSharing().toQueryLocator();

			// Verify
			Assert.isTrue(queryLocator.iterator().hasNext(), 'The user should have access to the tasks, so hasNext should return true.');
		}
	}

	@IsTest
	static void querySynchronousCloseToLimitWithMocking() {
		// Setup
		Exception queryException = null;

		rflib_SOQL.mock('mockingQuery').thenReturn(new List<Account>{
			new Account(Name = 'Test 1'),
			new Account(Name = 'Test 2')
		});

		// Test
		try {
			Test.startTest();
				for (Integer i = 0 ; i < 100 ; i++) {
					rflib_SOQL.of(Account.SObjectType).mockId('mockingQuery').toList();
				}
			Test.stopTest();
		} catch (QueryException e) {
			queryException = e;
		}

		// Verify
		Assert.isNull(queryException, 'The synchronous query should not have exceeded the limit.');
	}

	@IsTest
	static void querySynchronousLimitExceptionWithMocking() {
		// Setup
		Exception queryException = null;

		rflib_SOQL.mock('mockingQuery').thenReturn(new List<Account>{
			new Account(Name = 'Test 1'),
			new Account(Name = 'Test 2')
		});

		// Test
		try {
			Test.startTest();
				for (Integer i = 0 ; i < 101 ; i++) {
					rflib_SOQL.of(Account.SObjectType).mockId('mockingQuery').toList();
				}
			Test.stopTest();
		} catch (QueryException e) {
			queryException = e;
		}

		// Verify
		Assert.isNotNull(queryException, 'The synchronous query should have exceeded the limit.');
		Assert.areEqual('Too many rflib_SOQL queries.', queryException.getMessage(), 'The synchronous query should not have been exceeded.');
	}

	@IsTest
	static void querySynchronousLimitExceptionWithoutMocking() {
		// Setup
		Exception queryException = null;

		// Test
		try {
			for (Integer i = 0 ; i < 102 ; i++) {
				rflib_SOQL.of(Account.SObjectType).toList();
			}
		} catch (QueryException e) {
			queryException = e;
		}

		// Verify
		Assert.isNotNull(queryException, 'The synchronous query should have exceeded the limit.');
		Assert.areEqual('Too many rflib_SOQL queries.', queryException.getMessage(), 'The synchronous query should have been exceeded.');
	}

	@IsTest
	static void queryConverterToIdsOf() {
		// Setup
		List<Account> accounts = new List<Account>{
			new Account(Id = rflib_SOQL.IdGenerator.get(Account.SObjectType), ParentId = rflib_SOQL.IdGenerator.get(Account.SObjectType)),
			new Account(Id = rflib_SOQL.IdGenerator.get(Account.SObjectType), ParentId = rflib_SOQL.IdGenerator.get(Account.SObjectType))
		};

		// Test
		Set<Id> accountIds = new rflib_SOQL.Converter('Account').transform(accounts).toIdsOf(Account.ParentId);

		// Verify
		Assert.areEqual(accounts.size(), accountIds.size(), 'The size of the returned set should be equal to the size of the inserted accounts.');
	}

	@IsTest
	static void queryConverterToIdsOfRelationshipField() {
		// Setup
		List<Account> accounts = new List<Account>{
			new Account(Id = rflib_SOQL.IdGenerator.get(Account.SObjectType), Parent = new Account(Id = rflib_SOQL.IdGenerator.get(Account.SObjectType))),
			new Account(Id = rflib_SOQL.IdGenerator.get(Account.SObjectType), Parent = new Account(Id = rflib_SOQL.IdGenerator.get(Account.SObjectType)))
		};

		// Test
		Set<Id> accountIds = new rflib_SOQL.Converter('Account').transform(accounts).toIdsOf('Parent', Account.Id);

		// Verify
		Assert.areEqual(accounts.size(), accountIds.size(), 'The size of the returned set should be equal to the size of the inserted accounts.');
	}

	@IsTest
	static void queryConverterToValuesOf() {
		// Setup
		List<Account> accounts = new List<Account>{
			new Account(Id = rflib_SOQL.IdGenerator.get(Account.SObjectType), Name = 'Test 1'),
			new Account(Id = rflib_SOQL.IdGenerator.get(Account.SObjectType), Name = 'Test 2')
		};

		// Test
		Set<String> accountNames = new rflib_SOQL.Converter('Account').transform(accounts).toValuesOf(Account.Name);

		// Verify
		Assert.areEqual(accounts.size(), accountNames.size(), 'The size of the returned set should be equal to the size of the inserted accounts.');
		Assert.isTrue(accountNames.contains('Test 1'), 'The returned set should contain the account name "Test 1".');
		Assert.isTrue(accountNames.contains('Test 2'), 'The returned set should contain the account name "Test 2".');
	}

	@SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
	@IsTest
	static void preview() {
		// Test
		rflib_SOQL.of(Account.SObjectType).preview().toList();
	}

	@SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
	@IsTest
	static void previewWithConditions() {
		// Test
		rflib_SOQL.of(Account.SObjectType)
			.whereAre(rflib_SOQL.FilterGroup
				.add(rflib_SOQL.Filter.with(Account.Name).equal('Test'))
				.add(rflib_SOQL.Filter.with(Account.Industry).equal('IT'))
			)
			.preview()
			.toList();
	}

	@SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
	@IsTest
	static void previewCount() {
		// Test
		rflib_SOQL.of(Account.SObjectType).count().preview().toInteger();
	}

	static List<Account> insertAccounts() {
		List<Account> accounts = new List<Account>{
			new Account(Name = 'Test 1'),
			new Account(Name = 'Test 2')
		};
		insert accounts;
		return accounts;
	}

	static List<Account> insertAccountsWithParents() {
		List<Account> parentAccounts = new List<Account>{
			new Account(Name = 'Test 1 Parent'),
			new Account(Name = 'Test 2 Parent')
		};
		insert parentAccounts;

		List<Account> accounts = new List<Account>{
			new Account(Name = 'Test 1', ParentId = parentAccounts[0].Id),
			new Account(Name = 'Test 2', ParentId = parentAccounts[1].Id)
		};
		insert accounts;

		return accounts;
	}

	static List<Case> insertCases() {
		List<Case> cases = new List<Case>{
			new Case(Status = 'New', Origin = 'Web'),
			new Case(Status = 'New', Origin = 'Web')
		};
		insert cases;
		return cases;
	}

	static void insertTasks() {
		insert new List<Task>{
			new Task(Subject = 'Test', Type = 'Other'),
			new Task(Subject = 'Test', Type = 'Other')
		};
	}

	static User minimumAccessUser() {
		return new User(
			Alias = 'newUser',
			Email = 'newuser@testorg.com',
			EmailEncodingKey = 'UTF-8',
			LastName = 'Testing',
			LanguageLocaleKey = 'en_US',
			LocaleSidKey = 'en_US',
			Profile = new Profile(Name = 'Minimum Access - Salesforce'),
			TimeZoneSidKey = 'America/Los_Angeles',
			Username = 'queryselector@testorg.com'
		);
	}
}