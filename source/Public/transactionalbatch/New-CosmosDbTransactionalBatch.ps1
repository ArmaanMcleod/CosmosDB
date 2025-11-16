function New-CosmosDbTransactionalBatch
{
    [CmdletBinding(SupportsShouldProcess = $true)]
    [OutputType([System.Object[]])]
    param (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [CosmosDb.Context]
        $Context,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $PartitionKey,

        [Parameter(Mandatory = $true)]
        [ValidateScript({ Assert-CosmosDbCollectionIdValid -Id $_ -ArgumentName 'CollectionId' })]
        [System.String]
        $CollectionId,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.Object[]]
        $Documents,

        [Parameter(Mandatory = $false)]
        [ValidateSet('Create', 'Upsert', 'Read', 'Replace', 'Delete')]
        [System.String]
        $OperationType = 'Create',

        [Parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [System.Boolean]
        $IsAtomic = $true,

        [Parameter()]
        [System.Management.Automation.SwitchParameter]
        $ReturnJson
    )

    $operations = $Documents | ForEach-Object {
        @{
            operationType = $OperationType
            resourceBody  = $_
        }
    }

    $batchBody = $operations | ConvertTo-Json -Depth 100 -Compress -AsArray

    $resourcePath = 'colls/{0}/docs' -f $CollectionId

    $headers = @{
        'x-ms-cosmos-is-batch-request' = $IsAtomic
        'x-ms-cosmos-batch-atomic'     = $true
        'x-ms-documentdb-partitionkey' = "[`"$PartitionKey`"]"
    }

    $shouldProcessMessage = $LocalizedData.ShouldExecuteTransactionalBatch -f $Documents.Count, $OperationType.ToLower(), $CollectionId, $PartitionKey
    if ($PSCmdlet.ShouldProcess('Azure', $shouldProcessMessage))
    {
        $result = Invoke-CosmosDbRequest `
            -Context $Context `
            -Method 'Post' `
            -ResourceType 'docs' `
            -ResourcePath $resourcePath `
            -Body $batchBody `
            -Headers $headers `
            -ApiVersion '2018-12-31'

        if ($ReturnJson.IsPresent)
        {
            return $result.Content
        }

        try
        {
            $batchOperations = $result.Content | ConvertFrom-Json
            return (Set-CosmosDbTransactionalBatchOperationType -BatchOperations $batchOperations)
        }
        catch
        {
            New-CosmosDbInvalidOperationException -Message ($LocalizedData.ErrorConvertingDocumentJsonToObject)
        }
    }
}
