try:
    import isb
except ImportError:
    import valju as isb
import pandas as pd
import datetime
    

def database():
    try:
        return isb.Databases.base_from_proxy("realestate_service", "rursiD-fawra4-tinwep", "realestate_service", "makro-website:europe-west2:makro-prod")
    except:
        return isb.Databases.base_from_proxy("realestate_service", "rursiD-fawra4-tinwep", "realestate_service")