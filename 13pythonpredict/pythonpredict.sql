def moving_average(d1: str, d2: str, alpha: float=0.2)->pd.DataFrame:
    SQL = '''
        SELECT C.city c, R2.goods g, R.ddate d, sum(R2.price * R2.volume) s
                      FROM recept R
                               JOIN recgoods R2 ON R.id = R2.id
                               JOIN client C ON R.client = C.id
                      WHERE R.ddate >= %(mindate)s
                        AND R.ddate <= %(maxdate)s
                      GROUP BY c, g, d
                      ORDER BY c, g, d;
    '''


    df = pd.read_sql(SQL, 
                engine, 
                params={'mindate': d1, 'maxdate': d2}, 
                parse_dates={'recept.ddate': dict(format='%Y%m%d'),}
                )
    
    dfs = df.set_index(['c', 'g'])
    dfs.drop('d', axis=1, inplace=True)
    dfs = dfs.ewm(alpha=alpha, adjust=False).mean()
    dfs.reset_index(level=[0,1], inplace=True)
    dfs.reset_index(drop=True, inplace=True)
    names = ['city', 'goods', 'date', 'sum']
    df.columns = names
    df['prediction'] = dfs['s']

    return df

