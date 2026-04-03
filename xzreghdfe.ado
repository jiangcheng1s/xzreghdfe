capture program drop xzreghdfe
program define xzreghdfe, rclass
    version 18.0

    syntax varlist(min=2 numeric) [if] [in], ///
        absorb(varlist) ///
        cluster(varname) ///
        target(varname) ///
        [vce(string) saving(string asis)]

    marksample touse

    gettoken depvar rhs : varlist

    * 默认 vce(cluster cluster)
    if "`vce'" == "" {
        local vceopt "vce(cluster `cluster')"
    }
    else {
        local vceopt "vce(`vce')"
    }

    preserve

        quietly reghdfe `depvar' `rhs' if `touse', ///
            absorb(`absorb') `vceopt'

        scalar b0  = _b[`target']
        scalar se0 = _se[`target']

        levelsof `cluster' if e(sample), local(firms)

        tempfile result
        tempname hh

        postfile `hh' long firm double b_loo db dfbeta se_loo tstat pval dse using `result', replace

        foreach f of local firms {
            quietly reghdfe `depvar' `rhs' if `touse' & `cluster' != `f', ///
                absorb(`absorb') `vceopt'

            scalar b     = _b[`target']
            scalar se    = _se[`target']
            scalar db    = b0 - b
            scalar dfb   = db / se0
            scalar tstat = b / se
            scalar pval  = 2*ttail(e(df_r), abs(tstat))
            scalar dse   = se0 - se

            post `hh' (`f') (b) (db) (dfb) (se) (tstat) (pval) (dse)
        }

        postclose `hh'

        restore

    if "`saving'" == "" {
    use `result', clear
}
else {
    save "`saving'", replace
}
end

