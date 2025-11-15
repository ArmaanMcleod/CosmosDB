function Set-CosmosDbTransactionalBatchOperationType
{
    [CmdletBinding()]
    [OutputType([System.Object[]])]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.Object[]]
        $BatchOperations
    )

    foreach ($item in $BatchOperations)
    {
        $item.PSObject.TypeNames.Insert(0, 'CosmosDB.TransactionalBatchOperation')
    }

    return $BatchOperations
}
