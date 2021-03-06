# -*- coding: utf-8 -*-
"""
Created on Thu Sep 17 17:32:41 2015

@author: Hongjian
"""

import numpy as np
import matplotlib.pyplot as plt
from NBRegression import *




def plot_flowType_CrimeCount():
    xlabels = ['ARSON', 'ASSAULT', 'BATTERY', 'BURGLARY', 'CRIM SEXUAL ASSAULT', 
        'CRIMINAL DAMAGE', 'CRIMINAL TRESPASS', 'DECEPTIVE PRACTICE', 
        'GAMBLING', 'HOMICIDE', 'INTERFERENCE WITH PUBLIC OFFICER', 
        'INTIMIDATION', 'KIDNAPPING', 'LIQUOR LAW VIOLATION', 'MOTOR VEHICLE THEFT', 
        'NARCOTICS', 'OBSCENITY', 'OFFENSE INVOLVING CHILDREN', 'OTHER NARCOTIC VIOLATION',
        'OTHER OFFENSE', 'PROSTITUTION', 'PUBLIC INDECENCY', 'PUBLIC PEACE VIOLATION',
        'ROBBERY', 'SEX OFFENSE', 'STALKING', 'THEFT', 'WEAPONS VIOLATION', 'total']
    x = range(len(xlabels))
    
    ylabels = ['#jobs age under 29', 
    '#jobs age from 30 to 54', 
    '#jobs above 55', 
    '#jobs earning under \$1250/month', 
    '#jobs earnings from \$1251 to \$3333/month', 
    '#jobs above \$3333/month',
    '#jobs in goods producing', 
    '#jobs in trade transportation', 
    '#jobs in other services']
    y = range(len(ylabels))
        
        
    type_tag = 'mre2'
    
    d = np.loadtxt('{0}.array'.format(type_tag))
    for i in range(d.shape[0]):
        for j in range(d.shape[1]):
            if abs(d[i,j]) > 1:
                d[i,j] /= abs(d[i,j])
    
    plt.figure(num=1, figsize=(16,8))
    img = plt.matshow(d, fignum=1)
    plt.colorbar(img)
    plt.xticks(x, xlabels, rotation='vertical')
    plt.yticks(y, ylabels)
    plt.savefig('{0}.png'.format(type_tag), format='png')




def plot_corina_features():
    """
    Anomalous community area has index 24 (starting 0)
    """
    feats = generate_corina_features()
    header = feats[0]
    f = feats[1]
    
    plt.figure(figsize=(10,18))
    for idx in range(len(header)):
        y = [e[idx] for e in f]
        plt.subplot(4, 2, idx+1)
        plt.plot(y)
        plt.axvline(x=24, lw=3, color='r', ls=':')
        plt.axvline(x=29, lw=3, color='r', ls=':')
        plt.axvline(x=31, lw=3, ls=':', color='r')
        plt.title(header[idx])
    
    plt.show()
        
        
def plot_lags():
    W = generate_transition_SocialLag(2010)
    X = generate_geographical_SpatialLag_ca()
    Yhat = retrieve_crime_count(2010, -1)
    
    C = generate_corina_features()
    popul = C[1][:,0].reshape((77,1))
    Yhat = np.divide(Yhat, popul) * 10000
    
    f1 = np.dot(W, Yhat)
    f2 = np.dot(X, Yhat)
    
    l1 = W * Yhat
    l2 = X * Yhat
    
    for i in range(l1.shape[0]):
        for j in range(l1.shape[1]):
            if l1[i][j] > 200:
                l1[i][j] = 200
    
    idx = [0, 9, 19, 26, 29, 35, 37, 39, 44, 49, 59, 69]
    
    plt.figure(num=1, figsize=(12,12))
    img = plt.matshow(l1, fignum=1)
    plt.colorbar(img)
    plt.xticks(idx, [str(i+1) for i in idx])
    plt.yticks(idx, [str(i+1) for i in idx])
    
    
    plt.figure(num=2, figsize=(12,12))
    img = plt.matshow(l2, fignum=2)
    plt.colorbar(img)
    plt.xticks(idx, [str(i+1) for i in idx])
    plt.yticks(idx, [str(i+1) for i in idx])
    
    
    plt.figure(num=3, figsize=(18, 5))
    plt.subplot(1,3,1)
    plt.plot(Yhat)
    plt.title('Total crime per 10,000 population')
    
    plt.subplot(1,3,2)
    plt.plot(f1)
    plt.title('Social lag')
    
    plt.subplot(1,3,3)
    plt.plot(f2)
    plt.title('Spatial lag')
    
    plt.figure(figsize=(12,4.5))
    plt.subplot(1,2,1)
    plt.plot(f1)
    plt.axvline(x=24, lw=3, ls=":", color='r')
    plt.axvline(x=29, lw=3, ls=':', color='r')
    plt.axvline(x=31, lw=3, ls=':', color='r')
    plt.title('Social lag')
    
    plt.subplot(1,2,2)
    plt.plot(f2)
    plt.axvline(x=24, lw=3, ls=":", color='r')
    plt.axvline(x=29, lw=3, ls=':', color='r')
    plt.axvline(x=31, lw=3, ls=':', color='r')
    plt.title('Spatial lag')
    plt.show()
        

if __name__ == '__main__':
#    plot_corina_features()
    plot_lags()

