function Set-CosmosDbTransactionalBatchOperationType
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        $BatchOperations
    )

    foreach ($item in $BatchOperations)
    {
        $item.PSObject.TypeNames.Insert(0, 'CosmosDB.TransactionalBatchOperation')
    }

    return $BatchOperations
}
