pro scm_ar5_test
; test simple climate model used for metric calculations in AR5

nyr=300
time=findgen(nyr)
E0=fltarr(nyr)
C0=fltarr(nyr)
T0=fltarr(nyr)

for i=0, 1, -1 do begin

ecstcr=[2.5,1.5]
C0=280.*(1.01^time < 2.)
idoub=min(where(C0 eq 280.*2.))
scm_ar5,E0,C0,T0,time,/Cinput,ecstcr=ecstcr
print,ecstcr,T0(nyr-1),T0(70)
E1=E0
Etrg=1000.-total(E1(0:idoub-1))
if Etrg gt 0. then E1(idoub:*)=E1(idoub:*)*Etrg/total(E1(idoub:*))
scm_ar5,E1,C1,T1,time,ecstcr=ecstcr
Etot=total(E1)
print,Etot

if i eq 1 then begin
  E0=E1
  C0=C1
  T0=T1
  E1=exp(-(time-70)^2/35.^2)
  E1=Etot*E1/total(E1)
  scm_ar5,E1,C1,T1,time,ecstcr=ecstcr
endif

title='Response to idealised emission scenario'

xrange=[0,300]
p1=plot(time,time,xrange=xrange,yrange=[0,30],title=title,ytitle='Emissions (PgC/year)',/nodata,$
  dimensions=[600,800],position=[0.12,0.7,0.95,0.95])
p1=plot(time,E0,/overplot,color='red',linestyle=0,thick=3)
p1=plot(time,E1,/overplot,color='red',linestyle=2,thick=3)
if i eq 1 then p1=text(0.4,0.9,'Different emission paths',/normal)
if i eq 1 then p1=text(0.4,0.87,'Same total cumulative emissions: 1000 PgC',/normal)

p2=plot(time,time,xrange=xrange,yrange=[250,600],ytitle='CO!D2!N concentration (ppmv)',/nodata,$
  /current,position=[0.12,0.4,0.95,0.65])
p2=plot(time,C0,/overplot,color='red',linestyle=0,thick=3)
p2=plot(time,C1,/overplot,color='red',linestyle=2,thick=3)
if i eq 1 then p1=text(0.4,0.47,'Different peak concentrations',/normal)

p3=plot(time,time,xrange=xrange,yrange=[0,4],$
  xtitle='Years from start of idealised increase',ytitle='Temperature (!Uo!NC)',/nodata,$
  /current,position=[0.12,0.1,0.95,0.35])
p3=plot(time,T0,/overplot,color='red',linestyle=0,thick=3)
p3=plot(time,T1,/overplot,color='red',linestyle=2,thick=3)
if i eq 1 then t3=text(0.4,0.3,'Similar peak warming after emissions stop',/normal)
if i eq 0 then arrow=arrow([270,300],[ecstcr(0),ecstcr(0)],color='red',thick=2,/data,target=p3)
if i eq 0 then p3=plot([300,300],[T0(nyr-1),ecstcr(0)],color='red',thick=1,linestyle=1,/overplot)
if i eq 0 then t3=text(250,ecstcr(0),'ECS',color='red',/data,target=p3)
if i eq 0 then arrow=arrow([40,70],[ecstcr(1),ecstcr(1)],color='red',thick=2,/data,target=p3)
if i eq 0 then t3=text(20,ecstcr(1),'TCR',color='red',/data,target=p3)
if i eq 1 then t3=text(145,ecstcr(1)+0.1,'TCRE',color='red',/data,target=p3)
if i eq 1 then arrow=arrow([80,140],[ecstcr(1),ecstcr(1)]+0.1,arrow_style=3,color='red',thick=2,/data,target=p3)

;if i eq 0 then p1.save,'ecstcr_schm0.png' else p1.save,'ecstcr_schm1.png'
;p1.close
;p2.close
;p3.close

endfor

;stop
; read in data from Gareth Jones
close,1
a=' '
openr,1,'/Users/myles/Documents/ipcc_ch10/box_fig/global_tas_April2013.dat'
n_o=153
obs=fltarr(n_o)
dat_in=fltarr(8,n_o)
for i=0, 26 do readf,1,a
readf,1,dat_in

t_o=dat_in(0,*)
obs(*)=dat_in(1,*)
; subtract climatology for display (does not affect fitting)
i_clim=where(t_o lt 1920 and t_o ge 1860)
obs=obs-reform(rebin(rebin(obs(i_clim),1),n_o))

i_dobs=fltarr(1,n_o)
i_dobs(where(t_o ge 2000 and t_o le 2009))=1./10.
T_diff=i_dobs#obs
print,'Temperature rise to 2010s:',T_diff

RCP_name=['RCP3PD','RCP45','RCP6','RCP85']
RCP_dir=['3-PD','4.5','6','8.5']

nyr=2300-1765

for n=0, 3 do begin
; Read in forcing data
close,1
openr,1,'RCPs/'+RCP_dir(n)+'/'+RCP_name(n)+'_MIDYEAR_RADFORCING.txt'
a=' '
for line=1,59 do readf,1,a
F_names=strsplit(a,/extract)
; get rid of stupid extra characters
index=[1,3+indgen(n_elements(F_names)-3)]
F_names=F_names(index)
n_f=n_elements(F_names)
forcing=fltarr(n_f,nyr)
readf,1,forcing
close,1

openr,1,'RCPs/'+RCP_dir(n)+'/'+RCP_name(n)+'_EMISSIONS.txt'
a=' '
for line=1,37 do readf,1,a
E_names=strsplit(a,/extract)
; get rid of stupid extra characters
index=[1,3+indgen(n_elements(E_names)-3)]
E_names=E_names(index)
n_e=n_elements(E_names)
emissions=fltarr(n_e,nyr)
readf,1,emissions
close,1
E_co2=reform(emissions(1,*)+emissions(2,*),nyr)
CEco2=total(E_co2,/cumulative)

time=reform(forcing(0,*),nyr)
E=fltarr(nyr)
C=fltarr(nyr)
T=fltarr(nyr)

p2=plot(time,time,xtitle='Year',ytitle='Warming',/nodata,yrange=[-1,6],xrange=[1800,2300],title='Response to scenario '+RCP_name(n))

F_tot=reform(forcing(1,*),nyr)
F_nat=reform(forcing(2,*)+forcing(3,*),nyr)
F_ogg=reform(forcing(5,*)-forcing(8,*),nyr)
F_aer=reform(forcing(4,*)-forcing(5,*),nyr)
F_co2=reform(forcing(8,*))

C_co2=280.*exp(F_co2/5.396)
E_inv=fltarr(nyr)
scm_ar5,E_inv,C_co2,T_co2,time,/Cinput,ecstcr=ecstcr,Cpreind=280.
CEinv=total(E_inv,/cumulative)
print,'MAGICC v inverted CE by 2010, 2100, 2300:',RCP_name(n)
print,format='(3f10.2)',CEco2(where(time eq 2010)),CEco2(where(time eq 2100)),CEco2(where(time eq 2300))
print,format='(3f10.2)',CEinv(where(time eq 2010)),CEinv(where(time eq 2100)),CEinv(where(time eq 2300))

;stop

i_diff=fltarr(1,nyr)
i_diff(where(time ge 2000 and time le 2009))=1./10.
i_2035=fltarr(1,nyr)
i_2035(where(time ge 1986 and time le 2005))=-1./20.
i_2035(where(time ge 2016 and time le 2035))=1./20.

i_clim=fltarr(1,nyr)
i_clim(where(time ge 1860 and time lt 1920))=-1./60.

i_obs=where(time ge min(t_o) and time le max(t_o))

data_out=fltarr(9,nyr)
data_out(0,*)=time
data_out(1,*)=999.
data_out(1,i_obs)=obs
data_out(2,*)=F_tot
data_out(3,*)=F_aer
data_out(4,*)=CEco2

color=['red','blue','red','blue']
scf=fltarr(4)
print,'Scaling factors and aerosol forcing in 2011 + forecast 1986-2005 to 2016-2035'
for i=0, 3 do begin
  if i eq 0 then ecstcr=[1.5,1.0] else if i eq 1 then ecstcr=[2.0,1.0] else if i eq 2 then ecstcr=[4.5,2.5] else ecstcr=[4.5,3.0]
;  stop
  C(*)=280.
  scm_ar5,E,C,T_tot,time,/Cinput,ecstcr=ecstcr,Cpreind=280.,forcing=F_tot
  scm_ar5,E,C,T_aer,time,/Cinput,ecstcr=ecstcr,Cpreind=280.,forcing=F_aer
  T_tot=T_tot+total(i_clim#T_tot)
  T_aer=T_aer+total(i_clim#T_aer)
  scf(i)=total((T_diff-i_diff#T_tot)/(i_diff#T_aer))
  scf(i)=(-0.1/F_aer(where(time eq 2011))-1.) > scf(i) < (-1.9/F_aer(where(time eq 2011))-1.)
  print,scf(i)+1.,(scf(i)+1.)*F_aer(where(time eq 2011)),i_2035#(T_tot+scf(i)*T_aer)
  T_tot=T_tot+scf(i)*T_aer
  T_tot=T_tot-total(i_diff#T_tot-T_diff)
  p2=plot(time,T_tot,/overplot,color=color(i)) 
  p2=plot(t_o,obs,linestyle=6,symbol='D',/overplot,color='black')
  data_out(5+i,*)=T_tot
;  if i eq 3 then stop
endfor
;p2.close

close,2
openw,2,RCP_name(n)+'_scm5.txt'
printf,2,'Output of simple 2-box model under '+RCP_name(n)+' radiative forcing'
printf,2,'Low  response ECS=1.5; TCR=1.0K; Aerosol scaled by:',1.+scf(0)
printf,2,'Low AR4 vals  ECS=2.0; TCR=1.0K; Aerosol scaled by:',1.+scf(1)
printf,2,'High response ECS=4.5; TCR=2.5K; Aerosol scaled by:',1.+scf(2)
printf,2,'High AR4 vals ECS=4.5; TCR=3.0K; Aerosol scaled by:',1.+scf(3)
printf,2,'Col 1: year, Col 2: observations; Col 3: total forcing, Col 4: aerosol forcing, Col 5: cumulative CO2; Col 6: high response, Col 7: low response'
for i=0, nyr-1 do printf,2,format='(9f10.2)',data_out(*,i)
close,2

table_header=['Output of simple 2-box model under '+RCP_name(n)+' radiative forcing',$
       string('Low  response ECS=1.5; TCR=1.0K; Aerosol scaled by:',1.+scf(0)),$
       string('Low AR4 vals  ECS=2.0; TCR=1.0K; Aerosol scaled by:',1.+scf(1)),$
       string('High response ECS=4.5; TCR=2.5K; Aerosol scaled by:',1.+scf(2)),$
       string('High AR4 vals ECS=4.5; TCR=3.0K; Aerosol scaled by:',1.+scf(3))]
header=['Year','Observations','Total forcing','Aerosol forcing','Cumulative CO2','Low response','Low - AR4','High response','High - AR4']
write_csv,RCP_name(n)+'_scm5.csv',data_out,header=header,table_header=table_header

endfor

return
end