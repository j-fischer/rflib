/**
 * Copyright (c) 2025 Beyond The Cloud Sp. z o.o. (BeyondTheCloud.Dev)
 * Licensed under the MIT License (https://github.com/beyond-the-cloud-dev/soql-lib/blob/main/LICENSE)
 *
 * PMD False Positives:
 * - CyclomaticComplexity: It is a library and we tried to put everything into ONE test class
 * - CognitiveComplexity: It is a library and we tried to put everything into ONE class
 * - ApexDoc: Variable names are self-documented.
**/
@SuppressWarnings('PMD.CyclomaticComplexity, PMD.CognitiveComplexity, PMD.ApexDoc, PMD.ClassNamingConventions')
@IsTest
private class rflib_SOQL_Test {
    @SuppressWarnings('PMD.AvoidHardcodingId')
    private static final Id FAKE_ACCOUNT_ID = '0013V00000WNCwCQAX';

    @IsTest
    static void ofSObjectType() {
        // Test
        String soql = rflib_SOQL.of(Account.SObjectType).toString();

        // Verify
        Assert.areEqual('SELECT Id FROM Account', soql);
    }

    @IsTest
    static void ofString() {
        // Test
        String soql = rflib_SOQL.of('Account').toString();

        // Verify
        Assert.areEqual('SELECT Id FROM Account', soql);
    }

    @IsTest
    static void count() {
        // Test
        String soql = rflib_SOQL.of(Account.SObjectType).count().toString();

        // Verify
        Assert.areEqual('SELECT COUNT() FROM Account', soql);
    }

    @IsTest
    static void countWithDefaultFields() {
        // Test
        String soql = rflib_SOQL.of(Account.SObjectType)
            .with(Account.Id, Account.Name)
            .count()
            .toString();

        // Verify
        Assert.areEqual('SELECT COUNT() FROM Account', soql);
    }

    @IsTest
    static void countSObjectField() {
        // Test
        String soql = rflib_SOQL.of(Opportunity.SObjectType)
            .count(Opportunity.Id)
            .count(Opportunity.CampaignId)
            .toString();

        // Verify
        Assert.areEqual('SELECT COUNT(Id), COUNT(CampaignId) FROM Opportunity', soql);
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
        Assert.areEqual('SELECT COUNT(Id), COUNT(CampaignId) FROM Opportunity', soql);
    }

    @IsTest
    static void countWithAlias() {
        // Test
        String soql = rflib_SOQL.of(Account.SObjectType).count(Account.Name, 'names').toString();

        // Verify
        Assert.areEqual('SELECT COUNT(Name) names FROM Account', soql);
    }

    @IsTest
    static void countRelated() {
        // Test
        String soql = rflib_SOQL.of(Contact.SObjectType)
            .count('Account', Account.Name)
            .toString();

        // Verify
        Assert.areEqual('SELECT COUNT(Account.Name) FROM Contact', soql);
    }

    @IsTest
    static void countRelatedWithAlias() {
        // Test
        String soql = rflib_SOQL.of(Contact.SObjectType)
            .count('Account', Account.Name, 'names')
            .toString();

        // Verify
        Assert.areEqual('SELECT COUNT(Account.Name) names FROM Contact', soql);
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
        Assert.areEqual('SELECT CampaignId, AVG(Amount) FROM Opportunity GROUP BY CampaignId', soql);
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
        Assert.areEqual('SELECT CampaignId, AVG(Amount) amount FROM Opportunity GROUP BY CampaignId', soql);
    }

    @IsTest
    static void avgRelated() {
        // Test
        String soql = rflib_SOQL.of(OpportunityLineItem.SObjectType)
            .avg('Opportunity', Opportunity.Amount)
            .toString();

        // Verify
        Assert.areEqual('SELECT AVG(Opportunity.Amount) FROM OpportunityLineItem', soql);
    }

    @IsTest
    static void avgRelatedWithAlias() {
        // Test
        String soql = rflib_SOQL.of(OpportunityLineItem.SObjectType)
            .avg('Opportunity', Opportunity.Amount, 'amount')
            .toString();

        // Verify
        Assert.areEqual('SELECT AVG(Opportunity.Amount) amount FROM OpportunityLineItem', soql);
    }

    @IsTest
    static void countDistinct() {
        // Test
        String soql = rflib_SOQL.of(Lead.SObjectType).countDistinct(Lead.Company).toString();

        // Verify
        Assert.areEqual('SELECT COUNT_DISTINCT(Company) FROM Lead', soql);
    }

    @IsTest
    static void countDistinctWithAlias() {
        // Test
        String soql = rflib_SOQL.of(CampaignMember.SObjectType)
            .countDistinct('Lead', Lead.Company)
            .toString();

        // Verify
        Assert.areEqual('SELECT COUNT_DISTINCT(Lead.Company) FROM CampaignMember', soql);
    }

    @IsTest
    static void countDistinctRelated() {
        // Test
        String soql = rflib_SOQL.of(CampaignMember.SObjectType)
            .countDistinct('Lead', Lead.Company, 'company')
            .toString();

        // Verify
        Assert.areEqual('SELECT COUNT_DISTINCT(Lead.Company) company FROM CampaignMember', soql);
    }

    @IsTest
    static void countDistinctRelatedWithAlias() {
        // Test
        String soql = rflib_SOQL.of(Lead.SObjectType).countDistinct(Lead.Company, 'company').toString();

        // Verify
        Assert.areEqual('SELECT COUNT_DISTINCT(Company) company FROM Lead', soql);
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
        Assert.areEqual('SELECT FirstName, LastName, MIN(CreatedDate) FROM Contact GROUP BY FirstName, LastName', soql);
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
        Assert.areEqual('SELECT FirstName, LastName, MIN(CreatedDate) createdDate FROM Contact GROUP BY FirstName, LastName', soql);
    }

    @IsTest
    static void minRelated() {
        // Test
        String soql = rflib_SOQL.of(Contact.SObjectType)
            .min('Account', Account.CreatedDate)
            .toString();

        // Verify
        Assert.areEqual('SELECT MIN(Account.CreatedDate) FROM Contact', soql);
    }

    @IsTest
    static void minRelatedWithAlias() {
        // Test
        String soql = rflib_SOQL.of(Contact.SObjectType)
            .min('Account', Account.CreatedDate, 'createdDate')
            .toString();

        // Verify
        Assert.areEqual('SELECT MIN(Account.CreatedDate) createdDate FROM Contact', soql);
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
        Assert.areEqual('SELECT Name, MAX(BudgetedCost) FROM Campaign GROUP BY Name', soql);
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
        Assert.areEqual('SELECT Name, MAX(BudgetedCost) budgetedCost FROM Campaign GROUP BY Name', soql);
    }

    @IsTest
    static void maxRelated() {
        // Test
        String soql = rflib_SOQL.of(CampaignMember.SObjectType)
            .max('Campaign', Campaign.BudgetedCost)
            .toString();

        // Verify
        Assert.areEqual('SELECT MAX(Campaign.BudgetedCost) FROM CampaignMember', soql);
    }

    @IsTest
    static void maxRelatedhAlias() {
        // Test
        String soql = rflib_SOQL.of(CampaignMember.SObjectType)
            .max('Campaign', Campaign.BudgetedCost, 'budgetedCost')
            .toString();

        // Verify
        Assert.areEqual('SELECT MAX(Campaign.BudgetedCost) budgetedCost FROM CampaignMember', soql);
    }

    @IsTest
    static void sum() {
        // Test
        String soql = rflib_SOQL.of(Opportunity.SObjectType).sum(Opportunity.Amount).toString();

        // Verify
        Assert.areEqual('SELECT SUM(Amount) FROM Opportunity', soql);
    }

    @IsTest
    static void sumWithAlias() {
        // Test
        String soql = rflib_SOQL.of(Opportunity.SObjectType).sum(Opportunity.Amount, 'amount').toString();

        // Verify
        Assert.areEqual('SELECT SUM(Amount) amount FROM Opportunity', soql);
    }

    @IsTest
    static void sumRelated() {
        // Test
        String soql = rflib_SOQL.of(OpportunityLineItem.SObjectType)
            .sum('Opportunity', Opportunity.Amount)
            .toString();

        // Verify
        Assert.areEqual('SELECT SUM(Opportunity.Amount) FROM OpportunityLineItem', soql);
    }

    @IsTest
    static void sumRelatedWithAlias() {
        // Test
        String soql = rflib_SOQL.of(OpportunityLineItem.SObjectType)
            .sum('Opportunity', Opportunity.Amount, 'amount')
            .toString();

        // Verify
        Assert.areEqual('SELECT SUM(Opportunity.Amount) amount FROM OpportunityLineItem', soql);
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
        Assert.areEqual('SELECT LeadSource, Rating, GROUPING(LeadSource) grpLS, GROUPING(Rating) grpRating, COUNT(Name) cnt FROM Lead GROUP BY ROLLUP(LeadSource, Rating)', soql);
    }

    @IsTest
    static void toLabelWithSObjectField() {
        // Test
        String soql = rflib_SOQL.of(Lead.SObjectType)
            .with(Lead.Company)
            .toLabel(Lead.Status)
            .toString();

        // Verify
        Assert.areEqual('SELECT Company, toLabel(Status) FROM Lead', soql);
    }

    @IsTest
    static void toLabelWithStringField() {
        // Test
        String soql = rflib_SOQL.of(Lead.SObjectType)
            .with(Lead.Company)
            .toLabel('Recordtype.Name')
            .toString();

        // Verify
        Assert.areEqual('SELECT Company, toLabel(Recordtype.Name) FROM Lead', soql);
    }

    @IsTest
    static void formatWithSObjectField() {
        // Test
        String soql = rflib_SOQL.of(Opportunity.SObjectType)
            .format(Opportunity.Amount)
            .toString();

        // Verify
        Assert.areEqual('SELECT FORMAT(Amount)  FROM Opportunity', soql);
    }

    @IsTest
    static void formatWithAlias() {
        // Test
        String soql = rflib_SOQL.of(Opportunity.SObjectType)
            .format(Opportunity.Amount, 'amt')
            .toString();

        // Verify
        Assert.areEqual('SELECT FORMAT(Amount) amt FROM Opportunity', soql);
    }

    @IsTest
    static void withSObjectField() {
        // Test
        String soql = rflib_SOQL.of(Account.SObjectType)
            .with(Account.Name)
            .with(Account.BillingCity)
            .toString();

        // Verify
        Assert.areEqual('SELECT Name, BillingCity FROM Account', soql);
    }

    @IsTest
    static void withTwoSObjectFields() {
        // Test
        String soql = rflib_SOQL.of(Account.SObjectType)
            .with(Account.Name, Account.BillingCity)
            .toString();

        // Verify
        Assert.areEqual('SELECT Name, BillingCity FROM Account', soql);
    }

    @IsTest
    static void withThreeSObjectFields() {
        // Test
        String soql = rflib_SOQL.of(Account.SObjectType)
            .with(Account.Id, Account.Name, Account.BillingCity)
            .toString();

        // Verify
        Assert.areEqual('SELECT Id, Name, BillingCity FROM Account', soql);
    }

    @IsTest
    static void withFourSObjectFields() {
        // Test
        String soql = rflib_SOQL.of(Account.SObjectType)
            .with(Account.Id, Account.Name, Account.BillingCity, Account.AccountNumber)
            .toString();

        // Verify
        Assert.areEqual('SELECT Id, Name, BillingCity, AccountNumber FROM Account', soql);
    }

    @IsTest
    static void withFiveSObjectFields() {
        // Test
        String soql = rflib_SOQL.of(Account.SObjectType)
            .with(Account.Id, Account.Name, Account.BillingCity, Account.AccountNumber, Account.AccountSource)
            .toString();

        // Verify
        Assert.areEqual('SELECT Id, Name, BillingCity, AccountNumber, AccountSource FROM Account', soql);
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
        Assert.areEqual('SELECT Id, Name, Industry, AccountNumber, AnnualRevenue, BillingCity FROM Account', soql);
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
        Assert.areEqual('SELECT Id, Name, Industry, AccountNumber, AnnualRevenue, BillingCity FROM Account', soql);
    }

    @IsTest
    static void withStringFields() {
        // Test
        String soql = rflib_SOQL.of(Account.SObjectType)
            .with('Id, Name, BillingCity')
            .toString();

        // Verify
        Assert.areEqual('SELECT Id, Name, BillingCity FROM Account', soql);
    }

    @IsTest
    static void withStringAggregationAndGroupingFields() {
        // Test
        String soql = rflib_SOQL.of(Opportunity.SObjectType)
            .with('CampaignId campaign, AVG(Amount) amount')
            .groupBy(Opportunity.CampaignId)
            .toString();

        // Verify
        Assert.areEqual('SELECT CampaignId campaign, AVG(Amount) amount FROM Opportunity GROUP BY CampaignId', soql);
    }

    @IsTest
    static void withFieldAlias() {
        // Test
        String soql = rflib_SOQL.of(Account.SObjectType)
            .with(Account.Name, 'myAlias')
            .groupBy(Account.Name)
            .toString();

        // Verify
        Assert.areEqual('SELECT Name myAlias FROM Account GROUP BY Name', soql);
    }

    @IsTest
    static void withDuplicatedFields() {
        // Test
        String soql = rflib_SOQL.of(Account.SObjectType)
            .with('Id, Name, BillingCity')
            .with(Account.Id, Account.Name)
            .toString();

        // Verify
        Assert.areEqual('SELECT Id, Name, BillingCity FROM Account', soql);
    }

    @IsTest
    static void withRelatedField() {
        // Test
        String soql = rflib_SOQL.of(Account.SObjectType)
            .with(Account.Name, Account.BillingCity)
            .with('CreatedBy', User.Name)
            .toString();

        // Verify
        Assert.areEqual('SELECT Name, BillingCity, CreatedBy.Name FROM Account', soql);
    }

    @IsTest
    static void withTwoRelatedFields() {
        // Test
        String soql = rflib_SOQL.of(Account.SObjectType)
            .with(Account.Name, Account.BillingCity)
            .with('CreatedBy', User.Id, User.Name)
            .toString();

        // Verify
        Assert.areEqual('SELECT Name, BillingCity, CreatedBy.Id, CreatedBy.Name FROM Account', soql);
    }

    @IsTest
    static void withThreeRelatedFields() {
        // Test
        String soql = rflib_SOQL.of(Account.SObjectType)
            .with(Account.Name, Account.BillingCity)
            .with('CreatedBy', User.Id, User.Name, User.Alias)
            .toString();

        // Verify
        Assert.areEqual('SELECT Name, BillingCity, CreatedBy.Id, CreatedBy.Name, CreatedBy.Alias FROM Account', soql);
    }

    @IsTest
    static void withFourRelatedFields() {
        // Test
        String soql = rflib_SOQL.of(Account.SObjectType)
            .with(Account.Name, Account.BillingCity)
            .with('CreatedBy', User.Id, User.Name, User.Alias, User.City)
            .toString();

        // Verify
        Assert.areEqual('SELECT Name, BillingCity, CreatedBy.Id, CreatedBy.Name, CreatedBy.Alias, CreatedBy.City FROM Account', soql);
    }

    @IsTest
    static void withFiveRelatedFields() {
        // Test
        String soql = rflib_SOQL.of(Account.SObjectType)
            .with(Account.Name, Account.BillingCity)
            .with('CreatedBy', User.Id, User.Name, User.Alias, User.City, User.CompanyName)
            .toString();

        // Verify
        Assert.areEqual('SELECT Name, BillingCity, CreatedBy.Id, CreatedBy.Name, CreatedBy.Alias, CreatedBy.City, CreatedBy.CompanyName FROM Account', soql);
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
        Assert.areEqual('SELECT Name, BillingCity, CreatedBy.Id, CreatedBy.Name FROM Account', soql);
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
        Assert.areEqual('SELECT Name , (SELECT Id FROM Contacts) FROM Account', soql);
    }

    @IsTest
    static void withFieldSetException() {
         // Setup
         Exception queryException = null;

         // Test
         try {
            String soql = rflib_SOQL.of(Account.SObjectType)
                .withFieldSet('FieldSetName')
                .toString();
         } catch(Exception e) {
             queryException = e;
         }

        // Verify
        Assert.areEqual('FieldSet with name FieldSetName does not exist!', queryException.getMessage());
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
        Assert.areEqual('SELECT Name , (SELECT Id, Name FROM Contacts) FROM Account', soql);
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
        Assert.areEqual('SELECT Name , (SELECT Id, Name, AccountId FROM Contacts) FROM Account', soql);
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
        Assert.areEqual('SELECT Name , (SELECT Id, Name, AccountId, Email FROM Contacts) FROM Account', soql);
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
        Assert.areEqual('SELECT Name , (SELECT Id, Name, AccountId, Email, Phone FROM Contacts) FROM Account', soql);
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
        Assert.areEqual('SELECT Name , (SELECT Id, Name FROM Contacts) FROM Account', soql);
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
        Assert.areEqual('SELECT Name , (SELECT Id, Name, CreatedBy.Id, CreatedBy.Name FROM Contacts) FROM Account', soql);
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
        Assert.areEqual('SELECT Name , (SELECT LastName , (SELECT AssetLevel FROM Assets) FROM Contacts) FROM Account', soql);
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
        Assert.areEqual('SELECT Name , (SELECT Id, Name FROM Contacts WHERE (LastName = :v1)) FROM Account', soql);
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
        Assert.areEqual('SELECT Name , (SELECT Id, Name FROM Contacts WHERE LastName = :v1) FROM Account', soql);
    }

    @IsTest
    static void subQueryOrderBy() {
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
        Assert.areEqual('SELECT Name , (SELECT Id, Name FROM Contacts ORDER BY Name DESC NULLS LAST) FROM Account', soql);
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
        Assert.areEqual('SELECT Name , (SELECT Id, Name FROM Contacts ORDER BY CreatedBy.Name DESC NULLS LAST) FROM Account', soql);
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
        Assert.areEqual('SELECT Name , (SELECT Id, Name FROM Contacts LIMIT 10) FROM Account', soql);
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
        Assert.areEqual('SELECT Name , (SELECT Id, Name FROM Contacts OFFSET 100) FROM Account', soql);
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
        Assert.areEqual('SELECT Name , (SELECT Id, Name FROM Contacts FOR REFERENCE) FROM Account', soql);
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
        Assert.areEqual('SELECT Name , (SELECT Id, Name FROM Contacts FOR VIEW) FROM Account', soql);
    }

    @IsTest
    static void multipleSubQueriesWithConditions() {
        // Setup
        String leadSource = 'Web';
        Date fromDate = Date.newInstance(2024, 1, 1);
        Date toDate = Date.newInstance(2024, 1, 30);

        // Test
        rflib_SOQL builder = rflib_SOQL.of(Account.SObjectType)
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
            builder.toString()
        );

        Map<String, Object> binding = builder.binding();
        Assert.areEqual(fromDate, binding.get('v1'));
        Assert.areEqual(null, binding.get('v2'));
        Assert.areEqual(toDate, binding.get('v3'));
        Assert.areEqual(leadSource, binding.get('v4'));
        Assert.areEqual(fromDate, binding.get('v5'));
    }

    @IsTest
    static void delegatedScope() {
        // Test
        String soql = rflib_SOQL.of(Task.SObjectType)
            .delegatedScope()
            .toString();

        // Verify
        Assert.areEqual('SELECT Id FROM Task USING SCOPE DELEGATED', soql);
    }

    @IsTest
    static void mineScope() {
        // Test
        String soql = rflib_SOQL.of(Account.SObjectType)
            .mineScope()
            .toString();

        // Verify
        Assert.areEqual('SELECT Id FROM Account USING SCOPE MINE', soql);
    }

    @IsTest
    static void mineAndMyGroupsScope() {
        // Test
        String soql = rflib_SOQL.of(ProcessInstanceWorkItem.SObjectType)
            .mineAndMyGroupsScope()
            .toString();

        // Verify
        Assert.areEqual('SELECT Id FROM ProcessInstanceWorkitem USING SCOPE MINE_AND_MY_GROUPS', soql);
    }

    @IsTest
    static void myTerritoryScope() {
        // Test
        String soql = rflib_SOQL.of(Account.SObjectType)
            .myTerritoryScope()
            .toString();

        // Verify
        Assert.areEqual('SELECT Id FROM Account USING SCOPE MY_TERRITORY', soql);
    }

    @IsTest
    static void myTeamTerritoryScope() {
        // Test
        String soql = rflib_SOQL.of(Account.SObjectType)
            .myTeamTerritoryScope()
            .toString();

        // Verify
        Assert.areEqual('SELECT Id FROM Account USING SCOPE MY_TEAM_TERRITORY', soql);
    }

    @IsTest
    static void teamScope() {
        // Test
        String soql = rflib_SOQL.of(Account.SObjectType)
            .teamScope()
            .toString();

        // Verify
        Assert.areEqual('SELECT Id FROM Account USING SCOPE TEAM', soql);
    }

    @IsTest
    static void filterId() {
        // Test
        rflib_SOQL builder = rflib_SOQL.of(Account.SObjectType)
            .whereAre(rflib_SOQL.Filter.id().isNotNull());

        // Verify
        String soql = builder.toString();
        Assert.areEqual('SELECT Id FROM Account WHERE Id != :v1', soql);

        Map<String, Object> binding = builder.binding();
        Assert.areEqual(null, binding.get('v1'));
    }

    @IsTest
    static void filterRecordType() {
        // Test
        rflib_SOQL builder = rflib_SOQL.of(Account.SObjectType)
            .whereAre(rflib_SOQL.Filter.recordType().isNotNull());

        // Verify
        String soql = builder.toString();
        Assert.areEqual('SELECT Id FROM Account WHERE RecordType.DeveloperName != :v1', soql);

        Map<String, Object> binding = builder.binding();
        Assert.areEqual(null, binding.get('v1'));
    }

    @IsTest
    static void filterName() {
        // Test
        rflib_SOQL builder = rflib_SOQL.of(Account.SObjectType)
            .whereAre(rflib_SOQL.Filter.name().isNotNull());

        // Verify
        String soql = builder.toString();
        Assert.areEqual('SELECT Id FROM Account WHERE Name != :v1', soql);

        Map<String, Object> binding = builder.binding();
        Assert.areEqual(null, binding.get('v1'));
    }

    @IsTest
    static void filterWithRelatedField() {
        // Test
        rflib_SOQL builder = rflib_SOQL.of(Contact.SObjectType)
            .whereAre(rflib_SOQL.Filter.with('Account', Account.Name).equal('Test'));

        // Verify
        String soql = builder.toString();
        Assert.areEqual('SELECT Id FROM Contact WHERE Account.Name = :v1', soql);

        Map<String, Object> binding = builder.binding();
        Assert.areEqual('Test', binding.get('v1'));
    }

    @IsTest
    static void filterEqualString() {
        // Test
        rflib_SOQL builder = rflib_SOQL.of(Account.SObjectType)
            .whereAre(rflib_SOQL.Filter.with(Account.Name).equal('Test'));

        // Verify
        String soql = builder.toString();
        Assert.areEqual('SELECT Id FROM Account WHERE Name = :v1', soql);

        Map<String, Object> binding = builder.binding();
        Assert.areEqual('Test', binding.get('v1'));
    }

    @IsTest
    static void filterNotEqualString() {
        // Test
        rflib_SOQL builder = rflib_SOQL.of(Account.SObjectType)
            .whereAre(rflib_SOQL.Filter.with(Account.Name).notEqual('Test'));

        // Verify
        String soql = builder.toString();
        Assert.areEqual('SELECT Id FROM Account WHERE Name != :v1', soql);

        Map<String, Object> binding = builder.binding();
        Assert.areEqual('Test', binding.get('v1'));
    }

    @IsTest
    static void filterLessThan() {
        // Test
        rflib_SOQL builder = rflib_SOQL.of(Account.SObjectType)
            .whereAre(rflib_SOQL.Filter.with(Account.NumberOfEmployees).lessThan(10));

        // Verify
        String soql = builder.toString();
        Assert.areEqual('SELECT Id FROM Account WHERE NumberOfEmployees < :v1', soql);

        Map<String, Object> binding = builder.binding();
        Assert.areEqual(10, binding.get('v1'));
    }

    @IsTest
    static void filterGreaterThan() {
        // Test
        rflib_SOQL builder = rflib_SOQL.of(Account.SObjectType)
            .whereAre(rflib_SOQL.Filter.with(Account.NumberOfEmployees).greaterThan(10));

        // Verify
        String soql = builder.toString();
        Assert.areEqual('SELECT Id FROM Account WHERE NumberOfEmployees > :v1', soql);

        Map<String, Object> binding = builder.binding();
        Assert.areEqual(10, binding.get('v1'));
    }

    @IsTest
    static void filterLessOrEqual() {
        // Test
        rflib_SOQL builder = rflib_SOQL.of(Account.SObjectType)
            .whereAre(rflib_SOQL.Filter.with(Account.NumberOfEmployees).lessOrEqual(10));

        // Verify
        String soql = builder.toString();
        Assert.areEqual('SELECT Id FROM Account WHERE NumberOfEmployees <= :v1', soql);

        Map<String, Object> binding = builder.binding();
        Assert.areEqual(10, binding.get('v1'));
    }

    @IsTest
    static void filterGreaterOrEqual() {
        // Test
        rflib_SOQL builder = rflib_SOQL.of(Account.SObjectType)
            .whereAre(rflib_SOQL.Filter.with(Account.NumberOfEmployees).greaterOrEqual(10));

        // Verify
        String soql = builder.toString();
        Assert.areEqual('SELECT Id FROM Account WHERE NumberOfEmployees >= :v1', soql);

        Map<String, Object> binding = builder.binding();
        Assert.areEqual(10, binding.get('v1'));
    }

    @IsTest
    static void filterContains() {
        // Test
        rflib_SOQL builder = rflib_SOQL.of(Account.SObjectType)
            .whereAre(rflib_SOQL.Filter.with(Account.Name).contains('Test'));

        // Verify
        String soql = builder.toString();
        Assert.areEqual('SELECT Id FROM Account WHERE Name LIKE :v1', soql);

        Map<String, Object> binding = builder.binding();
        Assert.areEqual('%Test%', binding.get('v1'));
    }

    @IsTest
    static void filterContainsNull() {
        // Test
        rflib_SOQL builder = rflib_SOQL.of(Account.SObjectType)
            .whereAre(rflib_SOQL.Filter.with(Account.Name).contains(null));

        // Verify
        String soql = builder.toString();
        Assert.areEqual('SELECT Id FROM Account WHERE Name LIKE :v1', soql);

        Map<String, Object> binding = builder.binding();
        Assert.areEqual('%null%', binding.get('v1'));
    }

    @IsTest
    static void filterNotContains() {
        // Test
        rflib_SOQL builder = rflib_SOQL.of(Account.SObjectType)
            .whereAre(rflib_SOQL.Filter.with(Account.Name).notContains('Test'));

        // Verify
        String soql = builder.toString();
        Assert.areEqual('SELECT Id FROM Account WHERE (NOT Name LIKE :v1)', soql);

        Map<String, Object> binding = builder.binding();
        Assert.areEqual('%Test%', binding.get('v1'));
    }

    @IsTest
    static void filterContainsValues() {
        // Setup
        List<String> names = new List<String>{ 'Acc', 'My' };

        // Test
        rflib_SOQL builder = rflib_SOQL.of(Account.SObjectType)
            .whereAre(rflib_SOQL.Filter.with(Account.Name).containsSome(names));

        // Verify
        String soql = builder.toString();
        Assert.areEqual('SELECT Id FROM Account WHERE Name LIKE :v1', soql);

        Map<String, Object> binding = builder.binding();
        Assert.areEqual(names, binding.get('v1'));
    }

    @IsTest
    static void filterEndsWith() {
        // Test
        rflib_SOQL builder = rflib_SOQL.of(Account.SObjectType)
            .whereAre(rflib_SOQL.Filter.with(Account.Name).endsWith('Test'));

        // Verify
        String soql = builder.toString();
        Assert.areEqual('SELECT Id FROM Account WHERE Name LIKE :v1', soql);

        Map<String, Object> binding = builder.binding();
        Assert.areEqual('%Test', binding.get('v1'));
    }

    @IsTest
    static void filterNotEndsWith() {
        // Test
        rflib_SOQL builder = rflib_SOQL.of(Account.SObjectType)
            .whereAre(rflib_SOQL.Filter.with(Account.Name).notEndsWith('Test'));

        // Verify
        String soql = builder.toString();
        Assert.areEqual('SELECT Id FROM Account WHERE (NOT Name LIKE :v1)', soql);

        Map<String, Object> binding = builder.binding();
        Assert.areEqual('%Test', binding.get('v1'));
    }

    @IsTest
    static void filterStartsWith() {
        // Test
        rflib_SOQL builder = rflib_SOQL.of(Account.SObjectType)
            .whereAre(rflib_SOQL.Filter.with(Account.Name).startsWith('Test'));

        // Verify
        String soql = builder.toString();
        Assert.areEqual('SELECT Id FROM Account WHERE Name LIKE :v1', soql);

        Map<String, Object> binding = builder.binding();
        Assert.areEqual('Test%', binding.get('v1'));
    }

    @IsTest
    static void filterNotStartsWith() {
        // Test
        rflib_SOQL builder = rflib_SOQL.of(Account.SObjectType)
            .whereAre(rflib_SOQL.Filter.with(Account.Name).notStartsWith('Test'));

        // Verify
        String soql = builder.toString();
        Assert.areEqual('SELECT Id FROM Account WHERE (NOT Name LIKE :v1)', soql);

        Map<String, Object> binding = builder.binding();
        Assert.areEqual('Test%', binding.get('v1'));
    }

    @IsTest
    static void filterCustomContains() {
        // Test
        rflib_SOQL builder = rflib_SOQL.of(Account.SObjectType)
            .whereAre(rflib_SOQL.Filter.with(Account.Name).contains('_', 'Test', '%'));

        // Verify
        String soql = builder.toString();
        Assert.areEqual('SELECT Id FROM Account WHERE Name LIKE :v1', soql);

        Map<String, Object> binding = builder.binding();
        Assert.areEqual('_Test%', binding.get('v1'));
    }

    @IsTest
    static void filterCustomNotContains() {
        // Test
        rflib_SOQL builder = rflib_SOQL.of(Account.SObjectType)
            .whereAre(rflib_SOQL.Filter.with(Account.Name).notContains('_', 'Test', '%'));

        // Verify
        String soql = builder.toString();
        Assert.areEqual('SELECT Id FROM Account WHERE (NOT Name LIKE :v1)', soql);

        Map<String, Object> binding = builder.binding();
        Assert.areEqual('_Test%', binding.get('v1'));
    }

    @IsTest
    static void filterIsInSet() {
        // Setup
        Set<String> names = new Set<String>{ 'Test 1', 'Test 2' };

        // Test
        rflib_SOQL builder = rflib_SOQL.of(Account.SObjectType)
            .whereAre(rflib_SOQL.Filter.with(Account.Name).isIn(names));

        // Verify
        String soql = builder.toString();
        Assert.areEqual('SELECT Id FROM Account WHERE Name IN :v1', soql);

        Map<String, Object> binding = builder.binding();
        Assert.areEqual(names, binding.get('v1'));
    }

    @IsTest
    static void filterIsInList() {
        // Setup
        List<String> names = new List<String>{ 'Test 1', 'Test 2' };

        // Test
        rflib_SOQL builder = rflib_SOQL.of(Account.SObjectType)
            .whereAre(rflib_SOQL.Filter.with(Account.Name).isIn(names));

        // Verify
        String soql = builder.toString();
        Assert.areEqual('SELECT Id FROM Account WHERE Name IN :v1', soql);

        Map<String, Object> binding = builder.binding();
        Assert.areEqual(names, binding.get('v1'));
    }

    @IsTest
    static void filterNotInSet() {
        // Setup
        Set<String> names = new Set<String>{ 'Test 1', 'Test 2' };

        // Test
        rflib_SOQL builder = rflib_SOQL.of(Account.SObjectType)
            .whereAre(rflib_SOQL.Filter.with(Account.Name).notIn(names));

        // Verify
        String soql = builder.toString();
        Assert.areEqual('SELECT Id FROM Account WHERE Name NOT IN :v1', soql);

        Map<String, Object> binding = builder.binding();
        Assert.areEqual(names, binding.get('v1'));
    }

    @IsTest
    static void filterNotInList() {
        // Setup
        List<String> names = new List<String>{ 'Test 1', 'Test 2' };

        // Test
        rflib_SOQL builder = rflib_SOQL.of(Account.SObjectType)
            .with(Account.Name, Account.BillingCity)
            .whereAre(rflib_SOQL.Filter.with(Account.Name).notIn(names));

        // Verify
        String soql = builder.toString();
        Assert.areEqual('SELECT Name, BillingCity FROM Account WHERE Name NOT IN :v1', soql);

        Map<String, Object> binding = builder.binding();
        Assert.areEqual(names, binding.get('v1'));
    }

    @IsTest
    static void filterInlcudesAll() {
        // Setup
        List<String> ratings = new List<String>{ 'Hot', 'Warm' };

        // Test
        rflib_SOQL builder = rflib_SOQL.of(Account.SObjectType)
            .with(Account.Id)
            .whereAre(rflib_SOQL.Filter.with(Account.Rating).includesAll(ratings));

        // Verify
        String soql = builder.toString();
        Assert.areEqual('SELECT Id FROM Account WHERE Rating INCLUDES (\'Hot;Warm\')', soql);
    }

    @IsTest
    static void filterInlcudesSome() {
        // Setup
        List<String> ratings = new List<String>{ 'Hot', 'Warm' };

        // Test
        rflib_SOQL builder = rflib_SOQL.of(Account.SObjectType)
            .with(Account.Id)
            .whereAre(rflib_SOQL.Filter.with(Account.Rating).includesSome(ratings));

        // Verify
        String soql = builder.toString();
        Assert.areEqual('SELECT Id FROM Account WHERE Rating INCLUDES (\'Hot\', \'Warm\')', soql);
    }

    @IsTest
    static void filterExcludesAll() {
        // Setup
        List<String> ratings = new List<String>{ 'Hot', 'Warm' };

        // Test
        rflib_SOQL builder = rflib_SOQL.of(Account.SObjectType)
            .with(Account.Id)
            .whereAre(rflib_SOQL.Filter.with(Account.Rating).excludesAll(ratings));

        // Verify
        String soql = builder.toString();
        Assert.areEqual('SELECT Id FROM Account WHERE Rating EXCLUDES (\'Hot\', \'Warm\')', soql);
    }

    @IsTest
    static void filterExcludesSome() {
        // Setup
        List<String> ratings = new List<String>{ 'Hot', 'Warm' };

        // Test
        rflib_SOQL builder = rflib_SOQL.of(Account.SObjectType)
            .with(Account.Id)
            .whereAre(rflib_SOQL.Filter.with(Account.Rating).excludesSome(ratings));

        // Verify
        String soql = builder.toString();
        Assert.areEqual('SELECT Id FROM Account WHERE Rating EXCLUDES (\'Hot;Warm\')', soql);
    }

    @IsTest
    static void filterIsNull() {
        // Test
        rflib_SOQL builder = rflib_SOQL.of(Account.SObjectType)
            .whereAre(rflib_SOQL.Filter.with(Account.Name).isNull());

        // Verify
        String soql = builder.toString();
        Assert.areEqual('SELECT Id FROM Account WHERE Name = :v1', soql);

        Map<String, Object> binding = builder.binding();
        Assert.areEqual(null, binding.get('v1'));
    }

    @IsTest
    static void filterIsNotNull() {
        // Test
        rflib_SOQL builder = rflib_SOQL.of(Account.SObjectType)
            .whereAre(rflib_SOQL.Filter.with(Account.Name).isNotNull());

        // Verify
        String soql = builder.toString();
        Assert.areEqual('SELECT Id FROM Account WHERE Name != :v1', soql);

        Map<String, Object> binding = builder.binding();
        Assert.areEqual(null, binding.get('v1'));
    }

    @IsTest
    static void filterIsTrue() {
        // Test
        rflib_SOQL builder = rflib_SOQL.of(Account.SObjectType)
            .whereAre(rflib_SOQL.Filter.with(Account.IsDeleted).isTrue());

        // Verify
        String soql = builder.toString();
        Assert.areEqual('SELECT Id FROM Account WHERE IsDeleted = :v1', soql);

        Map<String, Object> binding = builder.binding();
        Assert.isTrue((Boolean) binding.get('v1'));
    }

    @IsTest
    static void filterIsFalse() {
        // Test
        rflib_SOQL builder = rflib_SOQL.of(Account.SObjectType)
            .whereAre(rflib_SOQL.Filter.with(Account.IsDeleted).isFalse());

        // Verify
        String soql = builder.toString();
        Assert.areEqual('SELECT Id FROM Account WHERE IsDeleted = :v1', soql);

        Map<String, Object> binding = builder.binding();
        Assert.isFalse((Boolean) binding.get('v1'));
    }

    @IsTest
    static void filterDateLiteral() {
        // Test
        String soql = rflib_SOQL.of(Account.SObjectType)
            .whereAre(rflib_SOQL.Filter.with(Account.CreatedDate).greaterThan('LAST_N_QUARTERS:2').asDateLiteral())
            .toString();

        // Verify
        Assert.areEqual('SELECT Id FROM Account WHERE CreatedDate > LAST_N_QUARTERS:2', soql);
    }

    @IsTest
    static void filtersGroup() {
        // Test
        rflib_SOQL builder = rflib_SOQL.of(Account.SObjectType)
            .whereAre(rflib_SOQL.FilterGroup
                .add(rflib_SOQL.Filter.with(Account.Name).equal('Test'))
                .add(rflib_SOQL.Filter.with(Account.BillingCity).equal('Krakow'))
            );

        // Verify
        String soql = builder.toString();
        Assert.areEqual('SELECT Id FROM Account WHERE (Name = :v1 AND BillingCity = :v2)', soql);

        Map<String, Object> binding = builder.binding();
        Assert.areEqual('Test', binding.get('v1'));
        Assert.areEqual('Krakow', binding.get('v2'));
    }

    @IsTest
    static void emptyFiltersGroup() {
        // Test
        rflib_SOQL builder = rflib_SOQL.of(Account.SObjectType)
            .whereAre(rflib_SOQL.FilterGroup);

        // Verify
        String soql = builder.toString();
        Assert.areEqual('SELECT Id FROM Account', soql);
    }

    @IsTest
    static void dynamicFiltersGroup() {
        // Setup
        rflib_SOQL.FilterGroup filterGroup = rflib_SOQL.FilterGroup;

        filterGroup.add(rflib_SOQL.Filter.with(Account.Name).equal('Test'));
        filterGroup.add(rflib_SOQL.Filter.with(Account.BillingCity).equal('Krakow'));

        // Test
        rflib_SOQL builder = rflib_SOQL.of(Account.SObjectType)
            .whereAre(filterGroup);

        // Verify
        String soql = builder.toString();
        Assert.areEqual('SELECT Id FROM Account WHERE (Name = :v1 AND BillingCity = :v2)', soql);

        Map<String, Object> binding = builder.binding();
        Assert.areEqual('Test', binding.get('v1'));
        Assert.areEqual('Krakow', binding.get('v2'));
    }

    @IsTest
    static void dynamicFiltersGroupOnSoqlInstance() {
        // Test
        rflib_SOQL builder = rflib_SOQL.of(Account.SObjectType)
            .whereAre(rflib_SOQL.Filter.with(Account.Industry).equal('IT'));

        Assert.areEqual('SELECT Id FROM Account WHERE Industry = :v1', builder.toString());

        builder.whereAre(
            rflib_SOQL.FilterGroup
                .add(rflib_SOQL.Filter.with(Account.Name).equal('Test'))
                .add(rflib_SOQL.Filter.with(Account.BillingCity).equal('Krakow'))
        );

        // Verify
        Assert.areEqual('SELECT Id FROM Account WHERE Industry = :v1 AND (Name = :v2 AND BillingCity = :v3)', builder.toString());

        Map<String, Object> binding = builder.binding();
        Assert.areEqual('IT', binding.get('v1'));
        Assert.areEqual('Test', binding.get('v2'));
        Assert.areEqual('Krakow', binding.get('v3'));
    }

    @IsTest
    static void multipleFilterGroups() {
        // Test
        rflib_SOQL builder = rflib_SOQL.of(Account.SObjectType)
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
            soql
        );

        Map<String, Object> binding = builder.binding();
        Assert.areEqual('%1%', binding.get('v1'));
        Assert.areEqual('%2%', binding.get('v2'));
        Assert.areEqual('%3%', binding.get('v3'));
        Assert.areEqual('%4%', binding.get('v4'));
        Assert.areEqual('%5%', binding.get('v5'));
        Assert.areEqual('%6%', binding.get('v6'));
        Assert.areEqual('%7%', binding.get('v7'));
        Assert.areEqual('%8%', binding.get('v8'));
        Assert.areEqual('%9%', binding.get('v9'));
        Assert.areEqual('%10%', binding.get('v10'));
        Assert.areEqual('%11%', binding.get('v11'));
    }

    @IsTest
    static void duplicatedConditionsInConditionOrder() {
        // Test
        rflib_SOQL builder = rflib_SOQL.of(Account.SObjectType)
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
            soql
        );

        Map<String, Object> binding = builder.binding();
        Assert.areEqual('%1%', binding.get('v1'));
        Assert.areEqual('%2%', binding.get('v2'));
        Assert.areEqual('%3%', binding.get('v3'));
        Assert.areEqual('%4%', binding.get('v4'));
        Assert.areEqual('%5%', binding.get('v5'));
        Assert.areEqual('%6%', binding.get('v6'));
        Assert.areEqual('%7%', binding.get('v7'));
        Assert.areEqual('%8%', binding.get('v8'));
        Assert.areEqual('%9%', binding.get('v9'));
        Assert.areEqual('%10%', binding.get('v10'));
        Assert.areEqual('%11%', binding.get('v11'));
    }

    @IsTest
    static void anyConditionMatchingForInnerGroup() {
        // Test
        rflib_SOQL builder = rflib_SOQL.of(Account.SObjectType)
            .whereAre(rflib_SOQL.FilterGroup
                .add(rflib_SOQL.Filter.with(Account.Name).equal('Test'))
                .add(rflib_SOQL.Filter.with(Account.BillingCity).equal('Krakow'))
                .anyConditionMatching()
            );

        // Verify
        String soql = builder.toString();
        Assert.areEqual('SELECT Id FROM Account WHERE (Name = :v1 OR BillingCity = :v2)', soql);

        Map<String, Object> binding = builder.binding();
        Assert.areEqual('Test', binding.get('v1'));
        Assert.areEqual('Krakow', binding.get('v2'));
    }

    @IsTest
    static void anyConditionMatchingForMainGroup() {
        // Test
        rflib_SOQL builder = rflib_SOQL.of(Account.SObjectType)
            .whereAre(rflib_SOQL.Filter.with(Account.Name).equal('Test'))
            .whereAre(rflib_SOQL.Filter.with(Account.BillingCity).equal('Krakow'))
            .anyConditionMatching();

        // Verify
        String soql = builder.toString();
        Assert.areEqual('SELECT Id FROM Account WHERE Name = :v1 OR BillingCity = :v2', soql);

        Map<String, Object> binding = builder.binding();
        Assert.areEqual('Test', binding.get('v1'));
        Assert.areEqual('Krakow', binding.get('v2'));
    }

    @IsTest
    static void conditionLogicForMainGroup() {
        // Test
        rflib_SOQL builder = rflib_SOQL.of(Account.SObjectType)
            .whereAre(rflib_SOQL.Filter.with(Account.Name).equal('Test'))
            .whereAre(rflib_SOQL.Filter.with(Account.BillingCity).equal('Krakow'))
            .conditionLogic('1 OR 2');

        // Verify
        String soql = builder.toString();
        Assert.areEqual('SELECT Id FROM Account WHERE Name = :v1 OR BillingCity = :v2', soql);

        Map<String, Object> binding = builder.binding();
        Assert.areEqual('Test', binding.get('v1'));
        Assert.areEqual('Krakow', binding.get('v2'));
    }

    @IsTest
    static void nestedFiltersGroup() {
        // Test
        rflib_SOQL builder = rflib_SOQL.of(Account.SObjectType)
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
        Assert.areEqual('SELECT Id FROM Account WHERE (Name = :v1 AND BillingCity = :v2 AND (Name = :v3 OR BillingCity = :v4))', soql);

        Map<String, Object> binding = builder.binding();
        Assert.areEqual('Test', binding.get('v1'));
        Assert.areEqual('Krakow', binding.get('v2'));
        Assert.areEqual('Test 2', binding.get('v3'));
        Assert.areEqual('Warsaw', binding.get('v4'));
    }

    @IsTest
    static void innerJoinWithFilterGroup() {
        // Test
        rflib_SOQL builder = rflib_SOQL.of(Account.SObjectType)
            .whereAre(rflib_SOQL.Filter.with(Account.Id).isIn(
                rflib_SOQL.InnerJoin.of(Contact.SObjectType)
                    .with(Contact.AccountId)
                    .whereAre(rflib_SOQL.FilterGroup
                        .add(rflib_SOQL.Filter.with(Contact.Name).equal('My Contact'))
                    )
            ));

        // Verify
        String soql = builder.toString();
        Assert.areEqual('SELECT Id FROM Account WHERE Id IN (SELECT AccountId FROM Contact WHERE (Name = :v1))', soql);

        Map<String, Object> binding = builder.binding();
        Assert.areEqual('My Contact', binding.get('v1'));
    }

    @IsTest
    static void inInnerJoin() {
        // Test
        rflib_SOQL builder = rflib_SOQL.of(Account.SObjectType)
            .whereAre(rflib_SOQL.Filter.with(Account.Id).isIn(
                rflib_SOQL.InnerJoin.of(Contact.SObjectType)
                    .with(Contact.AccountId)
                    .whereAre(rflib_SOQL.Filter.with(Contact.Name).equal('My Contact'))
            ));

        // Verify
        String soql = builder.toString();
        Assert.areEqual('SELECT Id FROM Account WHERE Id IN (SELECT AccountId FROM Contact WHERE Name = :v1)', soql);

        Map<String, Object> binding = builder.binding();
        Assert.areEqual('My Contact', binding.get('v1'));
    }

    @IsTest
    static void isNotInInnerJoin() {
        // Test
        rflib_SOQL builder = rflib_SOQL.of(Account.SObjectType)
            .whereAre(rflib_SOQL.Filter.with(Account.Id).notIn(
                rflib_SOQL.InnerJoin.of(Contact.SObjectType)
                    .with(Contact.AccountId)
                    .whereAre(rflib_SOQL.Filter.name().equal('My Contact'))
            ));

        // Verify
        String soql = builder.toString();
        Assert.areEqual('SELECT Id FROM Account WHERE Id NOT IN (SELECT AccountId FROM Contact WHERE Name = :v1)', soql);

        Map<String, Object> binding = builder.binding();
        Assert.areEqual('My Contact', binding.get('v1'));
    }

    @IsTest
    static void evaluateStringConditions() {
        // Test
        String soql = rflib_SOQL.of(Account.SObjectType)
            .whereAre('NumberOfEmployees >= 10 AND NumberOfEmployees <= 20')
            .toString();

        // Verify
        Assert.areEqual('SELECT Id FROM Account WHERE NumberOfEmployees >= 10 AND NumberOfEmployees <= 20', soql);
    }

    @IsTest
    static void evaluateEmptyConditions() {
        // Test
        String soql = rflib_SOQL.of(Account.SObjectType)
            .whereAre('')
            .toString();

        // Verify
        Assert.areEqual('SELECT Id FROM Account', soql);
    }

    @IsTest
    static void evaluateStringConditionsAndGroup() {
        // Test
        String soql = rflib_SOQL.of(Account.SObjectType)
            .whereAre('NumberOfEmployees >= 10 AND NumberOfEmployees <= 20')
            .whereAre(rflib_SOQL.Filter.name().equal('My Contact'))
            .toString();

        // Verify
        Assert.areEqual('SELECT Id FROM Account WHERE NumberOfEmployees >= 10 AND NumberOfEmployees <= 20 AND Name = :v1', soql);
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
        Assert.areEqual('SELECT Id FROM Account WHERE (NumberOfEmployees >= 10 AND NumberOfEmployees <= 20 AND Name = :v1)', soql);
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
        Assert.areEqual('SELECT Id FROM Account WHERE (BillingCity = :v1)', soql);
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
                    .add(rflib_SOQL.Filter.name().contains('MyAcccount'))
                )
            )
            .toString();

        // Verify
        Assert.areEqual('SELECT Id FROM Account WHERE ((Industry = :v1 AND Name LIKE :v2))', soql);
    }

    @IsTest
    static void groupBy() {
        // Test
        String soql = rflib_SOQL.of(Lead.SObjectType)
            .with(Lead.LeadSource)
            .groupBy(Lead.LeadSource)
            .toString();

        // Verify
        Assert.areEqual('SELECT LeadSource FROM Lead GROUP BY LeadSource', soql);
    }

    @IsTest
    static void groupByRelated() {
        // Test
        String soql = rflib_SOQL.of(OpportunityLineItem.SObjectType)
            .count(OpportunityLineItem.Name, 'count')
            .groupBy('OpportunityLineItem.Opportunity.Account', Account.Id)
            .toString();

        // Verify
        Assert.areEqual('SELECT COUNT(Name) count FROM OpportunityLineItem GROUP BY OpportunityLineItem.Opportunity.Account.Id', soql);
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
        Assert.areEqual(1, results.size());
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
        Assert.areEqual('SELECT LeadSource, COUNT(Name) cnt FROM Lead GROUP BY ROLLUP(LeadSource)', soql);
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
        Assert.areEqual('SELECT Status, LeadSource, COUNT(Name) cnt FROM Lead GROUP BY ROLLUP(Status, LeadSource)', soql);
    }

    @IsTest
    static void groupByRollupRelated() {
        // Test
        String soql = rflib_SOQL.of(Lead.SObjectType)
            .count(Lead.Name, 'cnt')
            .groupByRollup('ConvertedOpportunity', Opportunity.StageName)
            .toString();

        // Verify
        Assert.areEqual('SELECT COUNT(Name) cnt FROM Lead GROUP BY ROLLUP(ConvertedOpportunity.StageName)', soql);
    }

    @IsTest
    static void groupByCube() {
        // Test
        String soql = rflib_SOQL.of(Account.SObjectType)
            .with(Account.Type)
            .groupByCube(Account.Type)
            .toString();

        // Verify
        Assert.areEqual('SELECT Type FROM Account GROUP BY CUBE(Type)', soql);
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
        Assert.areEqual('SELECT Type, BillingCountry FROM Account GROUP BY CUBE(Type, BillingCountry)', soql);
    }

    @IsTest
    static void groupByCubeRelated() {
        // Test
        String soql = rflib_SOQL.of(Lead.SObjectType)
            .count(Lead.Name, 'cnt')
            .groupByCube('ConvertedOpportunity', Opportunity.StageName)
            .toString();

        // Verify
        Assert.areEqual('SELECT COUNT(Name) cnt FROM Lead GROUP BY CUBE(ConvertedOpportunity.StageName)', soql);
    }

    @IsTest
    static void differentGroupByFunctionsException() {
        // Setup
        Exception queryException = null;

        // Test
        try {
           String soql = rflib_SOQL.of(Account.SObjectType)
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
            queryException.getMessage()
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
        Assert.areEqual('SELECT LeadSource FROM Lead GROUP BY LeadSource', soql);
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
        Assert.areEqual('SELECT LeadSource, COUNT(Name) FROM Lead GROUP BY LeadSource', soql);
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
        Assert.areEqual('SELECT COUNT(Name) FROM Lead GROUP BY City HAVING City LIKE \'San%\'', soql);
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
        Assert.areEqual('SELECT COUNT(Name) FROM Lead GROUP BY City HAVING City LIKE \'San%\'', soql);
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
        Assert.areEqual('SELECT LeadSource, COUNT(Name) FROM Lead GROUP BY LeadSource HAVING COUNT(Name) > 100', soql);
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
        Assert.areEqual('SELECT LeadSource, AVG(Name) FROM Lead GROUP BY LeadSource HAVING AVG(Name) > 100', soql);
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
        Assert.areEqual('SELECT LeadSource, COUNT_DISTINCT(Name) FROM Lead GROUP BY LeadSource HAVING COUNT_DISTINCT(Name) > 100', soql);
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
        Assert.areEqual('SELECT LeadSource, MIN(NumberOfEmployees) FROM Lead GROUP BY LeadSource HAVING MIN(NumberOfEmployees) > 100', soql);
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
        Assert.areEqual('SELECT LeadSource, MAX(NumberOfEmployees) FROM Lead GROUP BY LeadSource HAVING MAX(NumberOfEmployees) > 100', soql);
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
        Assert.areEqual('SELECT LeadSource, SUM(AnnualRevenue) FROM Lead GROUP BY LeadSource HAVING SUM(AnnualRevenue) > 100', soql);
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
        Assert.areEqual('SELECT COUNT(Name) FROM Lead GROUP BY LeadSource HAVING LeadSource = null', soql);
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
        Assert.areEqual('SELECT LeadSource FROM Lead GROUP BY LeadSource HAVING LeadSource != null', soql);
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
        Assert.areEqual('SELECT COUNT(Name) FROM Lead GROUP BY IsConverted HAVING IsConverted = true', soql);
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
        Assert.areEqual('SELECT COUNT(Name) FROM Lead GROUP BY IsConverted HAVING IsConverted = false', soql);
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
        Assert.areEqual('SELECT COUNT(Name) FROM Lead GROUP BY LeadSource HAVING LeadSource = \'Web\'', soql);
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
        Assert.areEqual('SELECT COUNT(Name) FROM Lead GROUP BY LeadSource HAVING SUM(AnnualRevenue) = 10000', soql);
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
        Assert.areEqual('SELECT COUNT(Name) FROM Lead GROUP BY LeadSource HAVING LeadSource != \'Web\'', soql);
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
        Assert.areEqual('SELECT COUNT(Name) FROM Lead GROUP BY LeadSource HAVING SUM(AnnualRevenue) != 10000', soql);
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
        Assert.areEqual('SELECT COUNT(Name) FROM Lead GROUP BY LeadSource HAVING SUM(AnnualRevenue) < 10000', soql);
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
        Assert.areEqual('SELECT COUNT(Name) FROM Lead GROUP BY LeadSource HAVING SUM(AnnualRevenue) > 10000', soql);
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
        Assert.areEqual('SELECT COUNT(Name) FROM Lead GROUP BY LeadSource HAVING SUM(AnnualRevenue) <= 10000', soql);
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
        Assert.areEqual('SELECT COUNT(Name) FROM Lead GROUP BY LeadSource HAVING SUM(AnnualRevenue) >= 10000', soql);
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
        Assert.areEqual('SELECT SUM(AnnualRevenue) FROM Lead GROUP BY City HAVING City LIKE \'%San%\'', soql);
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
        Assert.areEqual('SELECT SUM(AnnualRevenue) FROM Lead GROUP BY City HAVING City LIKE \'_San%\'', soql);
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
        Assert.areEqual('SELECT SUM(AnnualRevenue) FROM Lead GROUP BY City HAVING (NOT City LIKE \'%San%\')', soql);
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
        Assert.areEqual('SELECT SUM(AnnualRevenue) FROM Lead GROUP BY City HAVING (NOT City LIKE \'_San%\')', soql);
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
        Assert.areEqual('SELECT SUM(AnnualRevenue) FROM Lead GROUP BY City HAVING City LIKE \'San%\'', soql);
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
        Assert.areEqual('SELECT SUM(AnnualRevenue) FROM Lead GROUP BY City HAVING (NOT City LIKE \'San%\')', soql);
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
        Assert.areEqual('SELECT SUM(AnnualRevenue) FROM Lead GROUP BY City HAVING City LIKE \'%San\'', soql);
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
        Assert.areEqual('SELECT SUM(AnnualRevenue) FROM Lead GROUP BY City HAVING (NOT City LIKE \'%San\')', soql);
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
        Assert.areEqual('SELECT SUM(AnnualRevenue) FROM Lead GROUP BY City HAVING City IN (\'San Francisco\', \'Los Angeles\')', soql);
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
        Assert.areEqual('SELECT SUM(AnnualRevenue) FROM Lead GROUP BY City HAVING City IN (\'San Francisco\', \'Los Angeles\')', soql);
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
        Assert.areEqual('SELECT SUM(AnnualRevenue) FROM Lead GROUP BY City HAVING City NOT IN (\'San Francisco\', \'Los Angeles\')', soql);
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
        Assert.areEqual('SELECT SUM(AnnualRevenue) FROM Lead GROUP BY City HAVING City NOT IN (\'San Francisco\', \'Los Angeles\')', soql);
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
        Assert.areEqual('SELECT LeadSource, COUNT(Name) FROM Lead GROUP BY LeadSource, City HAVING (COUNT(Name) > 100 AND City LIKE \'San%\')', soql);
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
        Assert.areEqual('SELECT LeadSource, COUNT(Name) FROM Lead GROUP BY LeadSource, City HAVING (COUNT(Name) > 100 AND City LIKE \'San%\')', soql);
    }

    @IsTest
    static void dynamicHavingFilterGroupOnSoqlInstance() {
        // Test
        rflib_SOQL builder = rflib_SOQL.of(Lead.SObjectType)
            .with(Lead.LeadSource)
            .count(Lead.Name)
            .groupBy(Lead.LeadSource)
            .groupBy(Lead.City)
            .have(rflib_SOQL.HavingFilter.WITH(Lead.LeadSource).equal('Web'));

        Assert.areEqual('SELECT LeadSource, COUNT(Name) FROM Lead GROUP BY LeadSource, City HAVING LeadSource = \'Web\'', builder.toString());

        builder.have(
            rflib_SOQL.HavingFilterGroup
                .add(rflib_SOQL.HavingFilter.count(Lead.Name).greaterThan(100))
                .add(rflib_SOQL.HavingFilter.with(Lead.City).startsWith('San'))
        );

        // Verify
        Assert.areEqual('SELECT LeadSource, COUNT(Name) FROM Lead GROUP BY LeadSource, City HAVING LeadSource = \'Web\' AND (COUNT(Name) > 100 AND City LIKE \'San%\')', builder.toString());
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
        Assert.areEqual('SELECT LeadSource, COUNT(Name) FROM Lead GROUP BY LeadSource, City HAVING (COUNT(Name) > 1) OR (COUNT(Name) > 2) OR (COUNT(Name) > 3) OR (COUNT(Name) > 4) OR (COUNT(Name) > 5) OR (COUNT(Name) > 6) OR (COUNT(Name) > 7) OR (COUNT(Name) > 8) OR (COUNT(Name) > 9) OR (COUNT(Name) > 10) OR (COUNT(Name) > 11)', soql);
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
        Assert.areEqual('SELECT LeadSource, COUNT(Name) FROM Lead GROUP BY LeadSource, City HAVING (COUNT(Name) > 100 OR City LIKE \'San%\')', soql);
    }

    @IsTest
    static void anyonditionMatchingForMainHavingFilterGroup() {
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
        Assert.areEqual('SELECT LeadSource, COUNT(Name) FROM Lead GROUP BY LeadSource, City HAVING COUNT(Name) > 100 OR City LIKE \'San%\'', soql);
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
        Assert.areEqual('SELECT LeadSource, COUNT(Name) FROM Lead GROUP BY LeadSource, City HAVING COUNT(Name) > 100 OR City LIKE \'San%\'', soql);
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
        Assert.areEqual('SELECT LeadSource, COUNT(Name) FROM Lead GROUP BY LeadSource HAVING ((COUNT(Name) > 100 AND COUNT(Name) < 200) AND (COUNT(Name) > 400 AND COUNT(Name) < 500))', soql);
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
        Assert.areEqual('SELECT LeadSource, COUNT(Name) FROM Lead GROUP BY LeadSource HAVING COUNT(Name) > 100 AND COUNT(Name) < 200', soql);
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
        Assert.areEqual('SELECT LeadSource, COUNT(Name) FROM Lead GROUP BY LeadSource HAVING (COUNT(Name) > 100 AND COUNT(Name) < 200) AND (COUNT(Name) > 400 AND COUNT(Name) < 500)', soql);
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
        Assert.areEqual('SELECT LeadSource, COUNT(Name) FROM Lead GROUP BY LeadSource HAVING ((COUNT(Name) > 100 AND COUNT(Name) < 200) AND COUNT(Name) < 500)', soql);
    }

    @IsTest
    static void orderByString() {
        // Test
        String soql = rflib_SOQL.of(Account.SObjectType)
            .orderBy('Industry').sortDesc().nullsLast()
            .orderBy('Id')
            .toString();

        // Verify
        Assert.areEqual('SELECT Id FROM Account ORDER BY Industry DESC NULLS LAST, Id ASC NULLS FIRST', soql);
    }

    @IsTest
    static void orderByDynamic() {
        // Test
        String soql = rflib_SOQL.of(Account.SObjectType)
            .orderBy('Industry', 'ASC')
            .toString();

        // Verify
        Assert.areEqual('SELECT Id FROM Account ORDER BY Industry ASC NULLS FIRST', soql);
    }

    @IsTest
    static void orderBy() {
        // Test
        String soql = rflib_SOQL.of(Account.SObjectType)
            .orderBy(Account.Industry).sortDesc().nullsLast()
            .orderBy(Account.Id)
            .toString();

        // Verify
        Assert.areEqual('SELECT Id FROM Account ORDER BY Industry DESC NULLS LAST, Id ASC NULLS FIRST', soql);
    }

    @IsTest
    static void orderByRelated() {
        // Test
        String soql = rflib_SOQL.of(Contact.SObjectType)
            .orderBy('Account', Account.Name)
            .toString();

        // Verify
        Assert.areEqual('SELECT Id FROM Contact ORDER BY Account.Name ASC NULLS FIRST', soql);
    }


    @IsTest
    static void setLimit() {
        // Test
        String soql = rflib_SOQL.of(Account.SObjectType)
            .setLimit(100)
            .toString();

        // Verify
        Assert.areEqual('SELECT Id FROM Account LIMIT 100', soql);
    }

    @IsTest
    static void offset() {
        // Test
        String soql = rflib_SOQL.of(Account.SObjectType)
            .offset(100)
            .toString();

        // Verify
        Assert.areEqual('SELECT Id FROM Account OFFSET 100', soql);
    }

    @IsTest
    static void forReference() {
        // Test
        String soql = rflib_SOQL.of(Account.SObjectType)
            .forReference()
            .toString();

        // Verify
        Assert.areEqual('SELECT Id FROM Account FOR REFERENCE', soql);
    }

    @IsTest
    static void forView() {
        // Test
        String soql = rflib_SOQL.of(Account.SObjectType)
            .forView()
            .toString();

        // Verify
        Assert.areEqual('SELECT Id FROM Account FOR VIEW', soql);
    }

    @IsTest
    static void forUpdate() {
        // Test
        String soql = rflib_SOQL.of(Account.SObjectType)
            .forUpdate()
            .toString();

        // Verify
        Assert.areEqual('SELECT Id FROM Account FOR UPDATE', soql);
    }

    @IsTest
    static void allRows() {
        // Test
        String soql = rflib_SOQL.of(Account.SObjectType)
            .allRows()
            .toString();

        // Verify
        Assert.areEqual('SELECT Id FROM Account ALL ROWS', soql);
    }

    @IsTest
    static void byId() {
        // Test
        rflib_SOQL builder = rflib_SOQL.of(Account.SObjectType).byId(FAKE_ACCOUNT_ID);

        // Verify
        String soql = builder.toString();
        Assert.areEqual('SELECT Id FROM Account WHERE Id = :v1', soql);

        Map<String, Object> binding = builder.binding();
        Assert.areEqual(FAKE_ACCOUNT_ID, binding.get('v1'));
    }

    @IsTest
    static void byIdSObject() {
        // Setup
        List<Case> cases = insertCases();

        // Test
        rflib_SOQL builder = rflib_SOQL.of(Case.SObjectType).byId(cases[0]);

        // Verify
        String soql = builder.toString();
        Assert.areEqual('SELECT Id FROM Case WHERE Id = :v1', soql);

        Map<String, Object> binding = builder.binding();
        Assert.areEqual(cases[0].Id, binding.get('v1'));
    }

    @IsTest
    static void byIdsSet() {
        Set<Id> accountIds = new Set<Id>{ FAKE_ACCOUNT_ID };

        rflib_SOQL builder = rflib_SOQL.of(Account.SObjectType).byIds(accountIds);

        // Verify
        String soql = builder.toString();
        Assert.areEqual('SELECT Id FROM Account WHERE Id IN :v1', soql);

        Map<String, Object> binding = builder.binding();
        Assert.areEqual(accountIds, binding.get('v1'));
    }

    @IsTest
    static void byIdsList() {
        // Setup
        List<Id> accountIds = new List<Id>{ FAKE_ACCOUNT_ID };

        // Test
        rflib_SOQL builder = rflib_SOQL.of(Account.SObjectType).byIds(accountIds);

        // Verify
        String soql = builder.toString();
        Assert.areEqual('SELECT Id FROM Account WHERE Id IN :v1', soql);

        Map<String, Object> binding = builder.binding();
        Assert.areEqual(accountIds, binding.get('v1'));
    }

    @IsTest
    static void byIdsSObjects() {
        // Setup
        List<Case> cases = insertCases();

        // Test
        rflib_SOQL builder = rflib_SOQL.of(Case.SObjectType).byIds(cases);

        // Verify
        String soql = builder.toString();
        Assert.areEqual('SELECT Id FROM Case WHERE Id IN :v1', soql);

        Map<String, Object> binding = builder.binding();
        Assert.areEqual(cases, binding.get('v1'));
    }

    @IsTest
    static void byRecordType() {
        // Setup
        String recordTypeDeveloperName = 'Partner';

        // Test
        rflib_SOQL builder = rflib_SOQL.of(Account.SObjectType).byRecordType(recordTypeDeveloperName);

        // Verify
        String soql = builder.toString();
        Assert.areEqual('SELECT Id FROM Account WHERE RecordType.DeveloperName = :v1', soql);

        Map<String, Object> binding = builder.binding();
        Assert.areEqual(recordTypeDeveloperName, binding.get('v1'));
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
            Assert.areEqual(testCase.Id, resultCase.Id);
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
            Assert.areEqual(2, cases.size());
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
            Assert.areEqual(2, casesAmount);
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
            Assert.isNull(resultTask);
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
            Assert.areEqual(0, tasks.size());
        }
    }

    @IsTest
    static void toIntegerWithSharing() {
        insertTasks();

        System.runAs(minimumAccessUser()) {
            // Test
            Integer tasksAmount = rflib_SOQL.of(Task.SObjectType).count().systemMode().withSharing().toInteger();

            // Verify
            Assert.areEqual(0, tasksAmount);
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
                Task task = (Task) rflib_SOQL.of(Task.SObjectType)
                    .with(Task.Type)
                    .userMode()
                    .toObject();
            } catch(Exception e) {
                queryException = e;
            }

            // Verify
            Assert.isTrue(queryException.getMessage().contains('No such column \'Type\' on entity \'Task\'.'));
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
                queryException.getMessage()
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
                queryException.getMessage()
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
        List<Account> result = rflib_SOQL.of(Account.SObjectType).mockId('mockingQuery').toList();

        // Verify
        Assert.areEqual(accounts, result);
    }

    @IsTest
    static void mockingSingleRecord() {
        // Setup
        Account testAccount = new Account(Name = 'Test 1');

        // Test
        rflib_SOQL.setMock('mockingQuery', testAccount);
        Account result = (Account) rflib_SOQL.of(Account.sObjectType).mockId('mockingQuery').toObject();

        // Verify
        Assert.areEqual(testAccount, result);
    }

    @IsTest
    static void mockingCount() {
        // Test
        rflib_SOQL.setCountMock('mockingQuery', 2);
        Integer result = rflib_SOQL.of(Account.sObjectType).count().mockId('mockingQuery').toInteger();

        // Verify
        Assert.areEqual(2, result);
    }

    @IsTest
    static void toId() {
        // Setup
        Account acc = new Account(Name = 'Test 1');
        insert acc;

        // Test
        Id accountId = rflib_SOQL.of(Account.SObjectType).byId(acc).toId();

        // Verify
        Assert.areEqual(acc.Id, accountId);
    }

    @IsTest
    static void doExist() {
        // Setup
        Account acc = new Account(Name = 'Test 1');
        insert acc;

        // Test
        Boolean isRecordExist = rflib_SOQL.of(Account.SObjectType).byId(acc).doExist();

        // Verify
        Assert.isTrue(isRecordExist);
    }

    @IsTest
    static void multipleToStringExecutions() {
        // Setup
        Exception soqlException = null;

        rflib_SOQL builder = rflib_SOQL.of(Account.SObjectType)
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
        Assert.isNull(soqlException);

        Assert.areEqual('SELECT Id FROM Account WHERE (Name = :v1 AND Industry = :v2)', builder.toString());

        Map<String, Object> binding = builder.binding();
        Assert.areEqual('Test', binding.get('v1'));
        Assert.areEqual('IT', binding.get('v2'));
    }

    @IsTest
    static void toValueOf() {
        // Setup
        Account acc = new Account(Name = 'Test 1');
        insert acc;

        // Test
        String resultAccName = (String) rflib_SOQL.of(Account.SObjectType).byId(acc).toValueOf(Account.Name);

        // Verify
        Assert.areEqual('Test 1', resultAccName);
    }

    @IsTest
    static void toValuesOf() {
        // Setup
        List<Account> accounts = insertAccounts();

        // Test
        Set<String> accountNames = rflib_SOQL.of(Account.SObjectType).byIds(accounts).toValuesOf(Account.Name);

        // Verify
        Assert.areEqual(2, accountNames.size());
    }

    @IsTest
    static void toValuesOfWhenNoValues() {
        // Setup
        insertAccounts(); // Industry is empty

        // Test
        Set<String> accountNames = rflib_SOQL.of(Account.SObjectType).toValuesOf(Account.Industry);

        // Verify
        Assert.areEqual(0, accountNames.size());
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
        Assert.areEqual(2, accountNames.size());
    }

    @IsTest
    static void toValueOfWhenRecordNotExist() {
        // Test
        String accountIndustry = (String) rflib_SOQL.of(Account.SObjectType)
            .whereAre(rflib_SOQL.Filter.name().equal('Test'))
            .toValueOf(Account.Industry);

        // Verify
        Assert.isNull(accountIndustry);
    }

    @IsTest
    static void toObject() {
        // Setup
        Account acc = new Account(Name = 'Test 1');
        insert acc;

        // Test
        Account result = (Account) rflib_SOQL.of(Account.SObjectType).toObject();

        // Verify
        Assert.areEqual(acc.Id, result.Id);
    }

    @IsTest
    static void toObjectWithMultipleRows() {
        // Setup
        insertAccounts();
        Exception queryException = null;

        // Test
        try {
            Account result = (Account) rflib_SOQL.of(Account.SObjectType).toObject();
        } catch (Exception e) {
            queryException = e; // List has more than 1 row for assignment to SObject
        }

        // Verify
        Assert.isNotNull(queryException);
    }

    @IsTest
    static void toObjectWithoutRows() {
        // Test
        // When List has no rows for assignment to SObject null will be returned
        Account account = (Account) rflib_SOQL.of(Account.SObjectType).toObject();

        // Verify
        Assert.isNull(account);
    }

    @IsTest
    static void toList() {
        // Setup
        List<Account> accounts = insertAccounts();

        // Test
        List<Account> result = rflib_SOQL.of(Account.SObjectType).toList();

        // Verify
        Assert.areEqual(accounts.size(), result.size());
    }

    @IsTest
    static void toAggregated() {
        // Setup
        List<Account> accounts = insertAccounts();

        // Test
        List<AggregateResult> result = rflib_SOQL.of(Account.SObjectType).count(Account.Name, 'names').toAggregated();

        // Verify
        Assert.areEqual(accounts.size(), result[0].get('names'));
    }

    @IsTest
    static void toIntegerWithoutSpecifiedCount() {
        // Setup
        List<Account> accounts = insertAccounts();

        // Test
        Integer result = rflib_SOQL.of(Account.SObjectType).toInteger();

        // Verify
        Assert.areEqual(accounts.size(), result);
    }

    @IsTest
    static void toInteger() {
        // Setup
        List<Account> accounts = insertAccounts();

        // Test
        Integer result = rflib_SOQL.of(Account.SObjectType).count().toInteger();

        // Verify
        Assert.areEqual(accounts.size(), result);
    }

    @IsTest
    static void toMap() {
        // Setup
        List<Account> accounts = insertAccounts();

        // Test
        Map<Id, Account> result = (Map<Id, Account>) rflib_SOQL.of(Account.SObjectType).toMap();

        // Verify
        Assert.areEqual(accounts.size(), result.size());

        for (Account acc : accounts) {
            Assert.isNotNull(result.get(acc.Id));
        }
    }

    @IsTest
    static void toMapWithCustomKey() {
        // Setup
        List<Account> accounts = insertAccounts();

        // Test
        Map<String, Account> result = (Map<String, Account>) rflib_SOQL.of(Account.SObjectType).toMap(Account.Name);

        // Verify
        Assert.areEqual(accounts.size(), result.size());

        for (Account acc : accounts) {
            Assert.isNotNull(result.get(acc.Name));
        }
    }

    @IsTest
    static void toMapWithCustomKeyAndCustomValue() {
        // Setup
        List<Account> accounts = insertAccounts();

        // Test
        Map<String, String> result = rflib_SOQL.of(Account.SObjectType).toMap(Account.Name, Account.Id);

        // Verify
        Assert.areEqual(accounts.size(), result.size());

        for (Account acc : accounts) {
            Assert.isNotNull(result.get(acc.Name));
        }
    }

    @IsTest
    static void toAggregatedMapWithCustomKey() {
        // Setup
        List<Account> accounts = insertAccounts();

        // Test
        Map<String, List<Account>> result = rflib_SOQL.of(Account.SObjectType).toAggregatedMap(Account.Name);

        // Verify
        Assert.areEqual(accounts.size(), result.size());

        for (Account acc : accounts) {
            Assert.isFalse(result.get(acc.Name).isEmpty());
        }
    }

    @IsTest
    static void toAggregatedMapWithEmptyCustomKey() {
        // Setup
        insertAccounts();

        // Test
        Map<String, List<Account>> result = rflib_SOQL.of(Account.SObjectType).toAggregatedMap(Account.Industry);

        // Verify
        Assert.areEqual(1, result.size()); // grouped by empty Industry
    }

    @IsTest
    static void toAggregatedMapWithCustomKeyAndCustomValue() {
        // Setup
        List<Account> accounts = insertAccounts();

        // Test
        Map<String, List<String>> result = rflib_SOQL.of(Account.SObjectType).toAggregatedMap(Account.Name, Account.Id);

        // Verify
        Assert.areEqual(accounts.size(), result.size());

        for (Account acc : accounts) {
            Assert.isFalse(result.get(acc.Name).isEmpty());
        }
    }

    @IsTest
    static void toQueryLocator() {
        // Test
        Database.QueryLocator queryLocator = rflib_SOQL.of(Account.SObjectType)
            .with(Account.Id)
            .with(Account.Name)
            .toQueryLocator();

        // Verify
        Assert.areEqual('SELECT Id, Name FROM Account', queryLocator.getQuery());
    }

    @IsTest
    static void toQueryLocatorWithSharing() {
        // Setup
        insertTasks();

        System.runAs(minimumAccessUser()) {
            // Test
            Database.QueryLocator queryLocator = rflib_SOQL.of(Task.SObjectType).systemMode().withSharing().toQueryLocator();

            // Verify
            Assert.isFalse(queryLocator.iterator().hasNext());
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
            Assert.isTrue(queryLocator.iterator().hasNext());
        }
    }

    static List<Account> insertAccounts() {
        List<Account> accounts = new List<Account>{
            new Account(Name = 'Test 1'),
            new Account(Name = 'Test 2')
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
            ProfileId = [SELECT Id FROM Profile WHERE Name = 'Minimum Access - Salesforce'].Id,
            TimeZoneSidKey = 'America/Los_Angeles',
            UserName = 'queryselector@testorg.com'
        );
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
}
